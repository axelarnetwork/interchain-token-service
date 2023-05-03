'use strict';

require('dotenv').config();

const { keccak256, defaultAbiCoder } = require('ethers/lib/utils');
const { deployTokenService, deployLinkerRouter, deployTokenDeployer } = require('../scripts/deploy.js');
const { createNetwork, networks, relay, evmRelayer, logger, stopAll, deployContract } = require('@axelar-network/axelar-local-dev');
const {
    ethers: {
        getDefaultProvider,
        Contract,
        Wallet,
        constants: { AddressZero },
    },
} = require('hardhat');
const { expect } = require('chai');

const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const ITokenService = require('../artifacts/contracts/interfaces/IInterchainTokenService.sol/IInterchainTokenService.json');
const ITokenDeployer = require('../artifacts/contracts/interfaces/ITokenDeployer.sol/ITokenDeployer.json');
const Test = require('../artifacts/contracts/test/TokenLinkerExecutableTest.sol/TokenLinkerExecutableTest.json');

logger.log = (args) => {};

const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
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

    before(async () => {
        const deployerAddress = new Wallet(deployerKey).address;
        const toFund = [deployerAddress];
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
        await tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], []);
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
        await tokenService.registerOriginToken(tokenAddress);

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
        await tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 });

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
        await tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 });

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
        await tokenService.registerOriginTokenAndDeployRemoteTokens(tokenAddress, destinationChains, gasValues, { value: 2e7 });

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

    it('Should be able to deploy and interchain token and deploy remote tokens in one go', async () => {
        const newSalt = keccak256('0x1234567890');
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, newSalt, true);

        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];

        await tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, newSalt, destinationChains, gasValues, {
            value: 2e7,
        });

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
        await token.mint(wallet.address, amount1);
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

        await tokenService.sendToken(tokenId, chains[1].name, wallet.address, amount1, { value: 1e6 });

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

        await tokenService.sendToken(tokenId, chains[2].name, wallet.address, amount1, { value: 1e6 });

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

        await tokenService.sendToken(tokenId, chains[0].name, wallet.address, amount1, { value: 1e6 });

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(0);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });
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

        await tokenService.callContractWithInterchainToken(
            tokenId,
            chains[1].name,
            chains[1].executable.address,
            amount1,
            defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]),
            { value: 1e6 },
        );

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

        await tokenService.callContractWithInterchainToken(
            tokenId,
            chains[2].name,
            wallet.address,
            amount1,
            defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]),
            { value: 1e6 },
        );
        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(2);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });
});
