'use strict';

require('dotenv').config();

const { deployTokenService, deployLinkerRouter, deployTokenDeployer } = require('../scripts/deploy.js');
const { createNetwork, networks, relay, evmRelayer, logger, stopAll, deployContract } = require('@axelar-network/axelar-local-dev');
const {
    ethers: {
        getDefaultProvider,
        Contract,
        Wallet,
        constants: { AddressZero },
        utils: { keccak256, defaultAbiCoder },
    },
} = require('hardhat');
const { expect } = require('chai');
const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const LinkerRouter = require('../artifacts/contracts/linkerRouter/LinkerRouter.sol/LinkerRouter.json');
const ITokenService = require('../artifacts/contracts/interfaces/IInterchainTokenService.sol/IInterchainTokenService.json');
const ITokenDeployer = require('../artifacts/contracts/interfaces/ITokenDeployer.sol/ITokenDeployer.json');
const Test = require('../artifacts/contracts/test/TokenLinkerExecutableTest.sol/TokenLinkerExecutableTest.json');
const { IAxelarExecutable } = require('@axelar-network/axelar-local-dev/dist/contracts/index.js');

logger.log = (args) => {};

const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
const notOwnerKey = keccak256(defaultAbiCoder.encode(['string'], ['not-owner']));
let chains;
const n = 3;

async function setupLocal(toFund) {
    for (let i = 0; i < n; i++) {
        const network = await createNetwork({ port: 8510 + i });
        const user = network.userWallets[0];

        for (const account of toFund) {
            await user
                .sendTransaction({
                    to: account,
                    value: BigInt(100e18),
                })
                .then((tx) => tx.wait());
        }
    }

    chains = networks.map((network) => {
        const info = network.getCloneInfo();
        info.rpc = info.rpc = `http://localhost:${network.port}`;
        return info;
    });
}

function loadChain(i = 0) {
    const chain = chains[i];
    const provider = getDefaultProvider(chain.rpc);
    const wallet = new Wallet(deployerKey, provider);
    const tokenService = new Contract(chain.interchainTokenService, ITokenService.abi, wallet);
    const tokenDeployer = new Contract(chain.tokenDeployer, ITokenDeployer.abi, wallet);
    return [wallet, tokenService, tokenDeployer];
}

async function getTokenData(i, salt, deployedAtService = false) {
    const [wallet, tokenService, tokenDeployer] = loadChain(i);
    let tokenAddress, tokenId;

    if (deployedAtService) {
        tokenAddress = await tokenService.getDeploymentAddress(wallet.address, salt);
        tokenId = await tokenService.getInterchainTokenId(wallet.address, salt);
    } else {
        tokenAddress = await tokenDeployer.getDeploymentAddress(tokenDeployer.address, salt);
        tokenId = await tokenService.getOriginTokenId(tokenAddress);
    }

    return [tokenAddress, tokenId];
}

async function expectRelayRevert(tx, withToken = false, n = 1) {
    const receipt = await (await tx).wait();
    const transactionHash = receipt.transactionHash;
    await relay();
    const contractCalls = Object.values(evmRelayer.relayData[`callContract${withToken ? 'WithToken' : ''}`]);

    for (let i = 0; i < n; i++) {
        const command = contractCalls[contractCalls.length - 1 - i];
        expect(command.transactionHash).to.equal(transactionHash);
        expect(command.execution).to.equal(undefined);
    }
}

describe('TokenService', () => {
    let token;
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `tokenServiceKey`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));
    const amount1 = 123456;

    const gatewayTokenName = 'GatewayToken';
    const gatewayTokenSymbol = 'GT';
    const gatewayTokenDecimals = 18;
    const gatewayTokenSalt = keccak256(defaultAbiCoder.encode(['string'], ['gatewayToken']));
    let gatewayTokenAddress, remoteGatewayTokenAddress;

    before(async () => {
        const deployerAddress = new Wallet(deployerKey).address;
        const notOwnerAddress = new Wallet(notOwnerKey).address;
        const toFund = [deployerAddress, notOwnerAddress];
        await setupLocal(toFund);

        for (const chain of chains) {
            const provider = getDefaultProvider(chain.rpc);
            const wallet = new Wallet(deployerKey, provider);
            await deployLinkerRouter(chain, wallet);
            await deployTokenDeployer(chain, wallet);
            await deployTokenService(chain, wallet);
            chain.executable = await deployContract(wallet, Test);
        }
    });

    after(async () => {
        await stopAll();
    });

    it('Should be able to deploy a native interchain token', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        await expect(tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], []))
            .to.emit(tokenService, 'TokenDeployed')
            .withArgs(tokenAddress, name, symbol, decimals, wallet.address)
            .and.to.emit(tokenService, 'TokenRegistered')
            .withArgs(tokenId, tokenAddress, true, false, false);
        token = new Contract(tokenAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);
    });

    it('Should not be able to deploy a native interchain token with the same sender and salt', async () => {
        const [wallet, tokenService] = loadChain(0);
        await expect(tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], [])).to.be.reverted;
    });

    it('Should not be able to register an origin token that does not exist', async () => {
        const [, tokenService] = loadChain(0);
        const [tokenAddress] = await getTokenData(0, salt, false);

        await expect(tokenService.registerOriginToken(tokenAddress)).to.be.reverted;
    });

    it('Should be able to register an origin token', async () => {
        const [wallet, tokenService, tokenDeployer] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, false);
        await tokenDeployer.deployToken(name, symbol, decimals, wallet.address, salt);
        token = new Contract(tokenAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
        await expect(tokenService.registerOriginToken(tokenAddress))
            .to.emit(tokenService, 'TokenRegistered')
            .withArgs(tokenId, tokenAddress, true, false, false);

        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);
    });
    it('Should not be able to register an origin token that has already been registered', async () => {
        const [, tokenService] = loadChain(0);
        const [tokenAddress] = await getTokenData(0, salt, false);
        await expect(tokenService.registerOriginToken(tokenAddress)).to.be.reverted;
    });
    it('Should not be able to register an origin token and deploy remote tokens if that token has already been registered', async () => {
        const [, tokenService] = loadChain(0);
        const [tokenAddress] = await getTokenData(0, salt, false);
        await expect(tokenService.registerOriginTokenAndDeployRemoteTokens(tokenAddress, [], [])).to.be.reverted;
    });
    it('Should not be able to register an origin token if that token is remote', async () => {
        const [, tokenService] = loadChain(1);
        const [, tokenId] = await getTokenData(0, salt, false);
        const tokenAddress = tokenService.getTokenAddress(tokenId);
        await expect(tokenService.registerOriginToken(tokenAddress, [], [])).to.be.reverted;
    });
    it('Should not be able to register an origin token and deploy remote tokens if that token is remote', async () => {
        const [, tokenService] = loadChain(1);
        const [, tokenId] = await getTokenData(0, salt, false);
        const tokenAddress = tokenService.getTokenAddress(tokenId);
        await expect(tokenService.registerOriginTokenAndDeployRemoteTokens(tokenAddress, [], [])).to.be.reverted;
    });
    it('Should be able to deploy a remote token for the origin token', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, false);
        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];
        await expect(tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }))
            .to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[0], gasValues[0])
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[1], gasValues[1]);
        await relay();

        for (const i of [1, 2]) {
            const [, tokenService] = loadChain(i);
            const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
            expect(remoteTokenAddress).to.not.equal(AddressZero);
            expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
        }
    });
    it('Should not be able to deploy a remote token for the origin token again', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, false);
        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];
        await expectRelayRevert(tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }), false, 2);
    });
    it('Should be able to deploy a remote token for the origin token deployed at the service', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, true);
        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];
        await expect(tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }))
            .to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[0], gasValues[0])
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[1], gasValues[1]);

        await relay();

        for (const i of [1, 2]) {
            const [, tokenService] = loadChain(i);
            const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
            expect(remoteTokenAddress).to.not.equal(AddressZero);
            expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
        }
    });
    it('Should not be able to deploy a remote token for the origin token deployed at the service again', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, true);
        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];
        await expectRelayRevert(tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }), false, 2);
    });
    it('Should be able to register a token and deploy remote tokens in one go', async () => {
        const newSalt = keccak256('0x1234567890');
        const [wallet, tokenService, tokenDeployer] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, newSalt, false);

        await tokenDeployer.deployToken(name, symbol, decimals, wallet.address, newSalt);

        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];

        await expect(tokenService.registerOriginTokenAndDeployRemoteTokens(tokenAddress, destinationChains, gasValues, { value: 2e7 }))
            .to.emit(tokenService, 'TokenRegistered')
            .withArgs(tokenId, tokenAddress, true, false, false)
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[0], gasValues[0])
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[1], gasValues[1]);

        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);

        await relay();

        for (const i of [1, 2]) {
            const [, tokenService] = loadChain(i);
            const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
            expect(remoteTokenAddress).to.not.equal(AddressZero);
            expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
        }
    });

    it('Should be able to deploy an interchain token and deploy remote tokens in one go', async () => {
        const newSalt = keccak256('0x1234567890');
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, newSalt, true);

        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];

        await expect(
            tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, newSalt, destinationChains, gasValues, {
                value: 2e7,
            }),
        )
            .to.emit(tokenService, 'TokenDeployed')
            .withArgs(tokenAddress, name, symbol, decimals, wallet.address)
            .and.to.emit(tokenService, 'TokenRegistered')
            .withArgs(tokenId, tokenAddress, true, false, false)
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[0], gasValues[0])
            .and.to.emit(tokenService, 'RemoteTokenRegisterInitialized')
            .withArgs(tokenId, destinationChains[1], gasValues[1]);

        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);

        await relay();

        for (const i of [1, 2]) {
            const [, tokenService] = loadChain(i);
            const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
            expect(remoteTokenAddress).to.equal(tokenAddress);
            expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
        }
    });

    it('Should be able to mint some token as the owner', async () => {
        const [wallet] = loadChain(0);
        const [tokenAddress] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        expect(await token.mint(wallet.address, amount1))
            .to.emit(token, 'Transfer')
            .withArgs(AddressZero, wallet.address, amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(amount1);
    });

    it('Should not be able to send some token to another chain without approval', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, true);

        await expect(tokenService.sendToken(tokenId, chains[1].name, wallet.address, amount1, { value: 1e6 })).to.be.reverted;
    });

    it('Should be able to send some token to another chain', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);

        const blockNumber = await wallet.provider.getBlockNumber();
        const sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

        await expect(tokenService.sendToken(tokenId, chains[1].name, wallet.address, amount1, { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[1].name, wallet.address.toLowerCase(), amount1, sendHash);

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(1);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });

    it('Should not be able to send some token to another chain with insufficient balance', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);

        await expect(tokenService.sendToken(tokenId, chains[1].name, wallet.address, amount1, { value: 1e6 })).to.be.reverted;

        await token.approve(tokenService.address, 0);
    });
    it('Should be able to send some token to a third chain', async () => {
        const [wallet, tokenService] = loadChain(1);
        const [, tokenId] = await getTokenData(0, salt, true);
        const tokenAddress = await tokenService.getTokenAddress(tokenId);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);

        const blockNumber = await wallet.provider.getBlockNumber();
        const sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

        await expect(tokenService.sendToken(tokenId, chains[2].name, wallet.address, amount1, { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[2].name, wallet.address.toLowerCase(), amount1, sendHash);

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(2);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });

    it('Should be able to send some token back to the original chain', async () => {
        const [wallet, tokenService] = loadChain(2);
        const [, tokenId] = await getTokenData(0, salt, true);
        const tokenAddress = await tokenService.getTokenAddress(tokenId);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);

        const blockNumber = await wallet.provider.getBlockNumber();
        const sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

        await expect(tokenService.sendToken(tokenId, chains[0].name, wallet.address, amount1, { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[0].name, wallet.address.toLowerCase(), amount1, sendHash);

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(0);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });

    for (let i = 0; i < 3; i++) {
        const j = (i + 1) % 3;
        it('Should be able to express send some token to another chain', async () => {
            const otherKey = keccak256('0x05968796');
            const [wallet, tokenService] = loadChain(i);
            const [, tokenId] = await getTokenData(0, salt, true);
            const tokenAddress = await tokenService.getTokenAddress(tokenId);
            const amount = amount1 / 2;
            const token = new Contract(tokenAddress, Token.abi, wallet);
            await token.approve(tokenService.address, amount1);

            let blockNumber = await wallet.provider.getBlockNumber();
            let sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

            await expect(tokenService.sendToken(tokenId, chains[j].name, wallet.address, amount, { value: 1e6 }))
                .to.emit(tokenService, 'Sending')
                .withArgs(chains[j].name, wallet.address.toLowerCase(), amount, sendHash);

            await relay();

            const [remoteWallet, remoteTokenService] = loadChain(j);
            const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
            const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);
            const otherWallet = new Wallet(otherKey, remoteWallet.provider);

            expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount);
            expect(Number(await token.balanceOf(wallet.address))).to.equal(amount1 - amount);

            blockNumber = await wallet.provider.getBlockNumber();
            sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

            await expect(tokenService.sendToken(tokenId, chains[j].name, otherWallet.address, amount, { value: 1e6 }))
                .to.emit(tokenService, 'Sending')
                .withArgs(chains[j].name, otherWallet.address.toLowerCase(), amount, sendHash);

            await remoteToken.approve(remoteTokenService.address, amount);

            await remoteTokenService.expressExecute(tokenId, otherWallet.address, amount, sendHash);

            expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(0);
            expect(Number(await remoteToken.balanceOf(otherWallet.address))).to.equal(amount);
            expect(Number(await token.balanceOf(wallet.address))).to.equal(0);

            await relay();

            expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount);
            expect(Number(await remoteToken.balanceOf(otherWallet.address))).to.equal(amount);
            expect(Number(await token.balanceOf(wallet.address))).to.equal(0);

            await remoteWallet.sendTransaction({ to: otherWallet.address, value: BigInt(1e17) });

            await remoteToken.connect(otherWallet).transfer(wallet.address, amount);
        });
    }

    it('Should not be able to send some token with data to another chain without approval', async () => {
        const val = 'Hello!';
        const [wallet, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, salt, true);

        await expect(
            tokenService.callContractWithInterchainToken(
                tokenId,
                chains[1].name,
                chains[1].executable.address,
                amount1,
                defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]),
                { value: 1e6 },
            ),
        ).to.be.reverted;
    });

    it('Should be able to send some token with data to another chain', async () => {
        const val = 'Hello!';
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);
        const payload = defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]);

        const blockNumber = await wallet.provider.getBlockNumber();
        const sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

        await expect(
            tokenService.callContractWithInterchainToken(tokenId, chains[1].name, chains[1].executable.address, amount1, payload, {
                value: 1e6,
            }),
        )
            .to.emit(tokenService, 'SendingWithData')
            .withArgs(wallet.address, chains[1].name, chains[1].executable.address.toLowerCase(), amount1, payload, sendHash);

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(1);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
        expect(await chains[1].executable.val()).to.equal(val);
    });

    it('Should not be able to send some token with data to another chain with insufficient balance', async () => {
        const val = 'Hello!';
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);

        await expect(
            tokenService.callContractWithInterchainToken(
                tokenId,
                chains[1].name,
                chains[1].executable.address,
                amount1,
                defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]),
                { value: 1e6 },
            ),
        ).to.be.reverted;
    });

    it('Should be able to send some token with data to a non-executable', async () => {
        const val = 'Hello!';
        const [wallet, tokenService] = loadChain(1);
        const [, tokenId] = await getTokenData(0, salt, true);
        const tokenAddress = await tokenService.getTokenAddress(tokenId);
        const token = new Contract(tokenAddress, Token.abi, wallet);
        await token.approve(tokenService.address, amount1);
        const payload = defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]);

        const blockNumber = await wallet.provider.getBlockNumber();
        const sendHash = keccak256(defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, wallet.address]));

        await expect(tokenService.callContractWithInterchainToken(tokenId, chains[2].name, wallet.address, amount1, payload, { value: 1e6 }))
            .to.emit(tokenService, 'SendingWithData')
            .withArgs(wallet.address, chains[2].name, wallet.address.toLowerCase(), amount1, payload, sendHash);
        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(2);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });

    it('Should deploy a gateway token to two chains', async () => {
        const [wallet, , tokenDeployer] = loadChain(0);
        await tokenDeployer.deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, wallet.address, gatewayTokenSalt);
        [gatewayTokenAddress] = await getTokenData(0, gatewayTokenSalt, false);
        await networks[0].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0, gatewayTokenAddress);
        expect(await networks[0].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(gatewayTokenAddress);
        const remoteGatewayToken = await networks[1].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0);
        remoteGatewayTokenAddress = remoteGatewayToken.address;
        expect(await networks[1].gateway.tokenAddresses(gatewayTokenSymbol)).to.not.equal(AddressZero);
        expect(await networks[2].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(AddressZero);
    });

    it('Should not be able to register gateway tokens as not the owner', async () => {
        const [wallet, tokenService] = loadChain(0);
        const notOwner = new Wallet(notOwnerKey, wallet.provider);
        await expect(tokenService.connect(notOwner).registerOriginGatewayToken(gatewayTokenSymbol)).to.be.reverted;
        await expect(tokenService.connect(notOwner).registerRemoteGatewayToken(gatewayTokenSymbol, keccak256('0x'), 'Anything')).to.be
            .reverted;
    });

    it('Should not be able to register gateway tokens that are not gateway tokens', async () => {
        const [, tokenService] = loadChain(0);
        const newSymbol = 'NS';

        await expect(tokenService.registerOriginGatewayToken(newSymbol)).to.be.reverted;
        await expect(tokenService.registerRemoteGatewayToken(newSymbol, keccak256('0x'), 'Anything')).to.be.reverted;
    });

    it('Should be able to register the origin token', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        await tokenService.registerOriginGatewayToken(gatewayTokenSymbol);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(gatewayTokenAddress);
        expect(await tokenService.getTokenId(gatewayTokenAddress)).to.equal(tokenId);

        expect(await tokenService.isOriginToken(tokenId)).to.be.true;
        expect(await tokenService.isGatewayToken(tokenId)).to.equal(true);
        expect(await tokenService.isRemoteGatewayToken(tokenId)).to.false;
        expect(await tokenService.getGatewayTokenSymbol(tokenId)).to.equal(gatewayTokenSymbol);
    });

    it('Should be able to register the remote token', async () => {
        const [, tokenService] = loadChain(1);
        const [, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        await tokenService.registerRemoteGatewayToken(gatewayTokenSymbol, tokenId, chains[0].name);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(remoteGatewayTokenAddress);
        expect(await tokenService.getTokenId(remoteGatewayTokenAddress)).to.equal(tokenId);

        expect(await tokenService.isOriginToken(tokenId)).to.equal(false);
        expect(await tokenService.isGatewayToken(tokenId)).to.equal(true);
        expect(await tokenService.isRemoteGatewayToken(tokenId)).to.equal(false);
        expect(await tokenService.getGatewayTokenSymbol(tokenId)).to.equal(gatewayTokenSymbol);
    });

    it('Should not be able to deploy the gateway token to a the chain that has the token', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        await expectRelayRevert(tokenService.deployRemoteTokens(tokenId, [chains[1].name], [1e7], { value: 1e7 }));
    });

    it('Should be able to deploy the gateway token to a third chain', async () => {
        const [, tokenService] = loadChain(0);
        const [, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        await tokenService.deployRemoteTokens(tokenId, [chains[2].name], [1e7], { value: 1e7 });

        await relay();

        const [, remoteTokenService] = loadChain(2);
        expect(await remoteTokenService.getTokenAddress(tokenId)).to.not.equal(AddressZero);

        expect(await remoteTokenService.isOriginToken(tokenId)).to.equal(false);
        expect(await remoteTokenService.isGatewayToken(tokenId)).to.equal(false);
        expect(await remoteTokenService.isRemoteGatewayToken(tokenId)).to.equal(true);
    });

    it('Should be able to add gateway supported chains to the linker routers', async () => {
        for (let i = 0; i < 3; i++) {
            const [wallet, tokenService] = loadChain(i);
            const linkerRouter = new Contract(await tokenService.linkerRouter(), LinkerRouter.abi, wallet);

            const names = [];

            for (let j = 0; j < 2; j++) {
                if (i === j) continue;
                names.push(chains[j].name);
            }

            await linkerRouter.addGatewaySupportedChains(names);

            for (let j = 0; j < 3; j++) {
                if (i === j) continue;
                expect(await linkerRouter.supportedByGateway(chains[j].name)).to.equal(j < 2);
            }
        }
    });

    it('Should be able send some token to every chain from the origin chain', async () => {
        const amount = 1e6;
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        const originToken = new Contract(tokenAddress, Token.abi, wallet);

        await originToken.mint(wallet.address, 2 * amount);

        await originToken.approve(tokenService.address, 2 * amount);

        for (let i = 1; i < 3; i++) {
            await tokenService.sendToken(tokenId, chains[i].name, wallet.address, amount, { value: 1e6 });

            await relay();

            const [remoteWallet, remoteService] = loadChain(i);

            const remoteTokenAddress = await remoteService.getTokenAddress(tokenId);

            const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

            expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount);
        }
    });

    it('Should be able send some token to every other chain from the other chains', async () => {
        const amount = 1e5;
        const [, tokenId] = await getTokenData(0, gatewayTokenSalt, false);

        for (let i = 1; i < 3; i++) {
            const [wallet, tokenService] = loadChain(i);

            const tokenAddress = await tokenService.getTokenAddress(tokenId);
            const token = new Contract(tokenAddress, Token.abi, wallet);

            await token.approve(tokenService.address, 2 * amount);

            for (let j = 0; j < 3; j++) {
                if (i === j) continue;

                const [remoteWallet, remoteService] = loadChain(j);

                const otherTokenAddress = await remoteService.getTokenAddress(tokenId);

                const otherToken = new Contract(otherTokenAddress, Token.abi, remoteWallet);
                const balance = Number(await otherToken.balanceOf(wallet.address));

                await tokenService.sendToken(tokenId, chains[j].name, wallet.address, amount, { value: 1e6 });

                await relay();

                if (i + j === 3) {
                    await relay();
                    let commands;

                    if (i === 1) {
                        commands = evmRelayer.relayData.callContract;
                    } else {
                        commands = evmRelayer.relayData.callContractWithToken;
                    }

                    const commandIds = Object.keys(commands);
                    commands = Object.values(commands);

                    const payload = commands[commands.length - 1].payload;
                    const commandId = commandIds[commandIds.length - 1];

                    const executable = new Contract(remoteService.address, IAxelarExecutable.abi, remoteWallet);

                    if (i === 1) {
                        await executable.execute(commandId, chains[0].name, remoteService.address, payload);
                    } else {
                        await executable.executeWithToken(
                            commandId,
                            chains[0].name,
                            remoteService.address,
                            payload,
                            await token.symbol(),
                            amount,
                        );
                    }
                }

                expect(Number(await otherToken.balanceOf(wallet.address))).to.equal(balance + amount);
            }
        }
    });

    it('Should be able to set a mint limit for a new token', async () => {
        const salt = keccak256('0x96858473');
        const mintLimit = 125;
        const [wallet, tokenService] = loadChain(0);

        await tokenService.deployInterchainToken('Mint Limit Test', 'MLT', 18, wallet.address, salt, [chains[1].name], [1e7], {
            value: 1e7,
        });

        await relay();

        const [, tokenId] = await getTokenData(0, salt, true);
        expect(await tokenService.getTokenMintLimit(tokenId)).to.equal(0);

        await tokenService.setTokenMintLimit(tokenId, mintLimit);

        expect(await tokenService.getTokenMintLimit(tokenId)).to.equal(mintLimit);

        const [, remoteTokenService] = loadChain(1);

        expect(await remoteTokenService.getTokenMintLimit(tokenId)).to.equal(0);

        await remoteTokenService.setTokenMintLimit(tokenId, mintLimit);

        expect(await remoteTokenService.getTokenMintLimit(tokenId)).to.equal(mintLimit);
    });

    it('Should be able to sent up to the mint limit but no more', async () => {
        const salt = keccak256('0x96858473');
        const mintLimit = 125;
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);

        const token = new Contract(tokenAddress, Token.abi, wallet);

        await token.mint(wallet.address, mintLimit * 2);

        await token.approve(tokenService.address, mintLimit * 2);

        await tokenService.sendToken(tokenId, chains[1].name, wallet.address, mintLimit, { value: 1e6 });

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(1);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);

        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(await remoteToken.balanceOf(wallet.address)).to.equal(mintLimit);

        await expectRelayRevert(tokenService.sendToken(tokenId, chains[1].name, wallet.address, mintLimit, { value: 1e6 }));
    });
});
