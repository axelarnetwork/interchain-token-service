'use strict';

require('dotenv').config();

const { deployTokenService, deployLinkerRouter, deployTokenDeployer } = require('../scripts/deploy.js');
const { createNetwork, networks, relay, logger, stopAll, deployContract } = require('@axelar-network/axelar-local-dev');
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
const Token = require('../artifacts/contracts/interfaces/IInterchainToken.sol/IInterchainToken.json');
const ITokenService = require('../artifacts/contracts/interfaces/IInterchainTokenService.sol/IInterchainTokenService.json');
const ITokenDeployer = require('../artifacts/contracts/interfaces/ITokenDeployer.sol/ITokenDeployer.json');
const Test = require('../artifacts/contracts/test/TokenLinkerExecutableTest.sol/TokenLinkerExecutableTest.json');
const TestToken = require('../artifacts/contracts/test/InterchainTokenTest.sol/InterchainTokenTest.json');
const { deployCreate3Contract } = require('@axelar-network/axelar-gmp-sdk-solidity');

logger.log = (args) => {};

const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
const notOwnerKey = keccak256(defaultAbiCoder.encode(['string'], ['not-owner']));
let chains;
let interchainTokenAddress;
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

describe('Token', () => {
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `tokenServiceKey`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));
    const amount1 = 123456;

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

    it('Should be able to deploy an interchain token and deploy remote tokens in one go', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);

        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];

        await expect(
            tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, destinationChains, gasValues, {
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

    it('Should be able to send some token to another chain', async () => {
        const [wallet, tokenService] = loadChain(0);
        const [tokenAddress, tokenId] = await getTokenData(0, salt, true);
        const token = new Contract(tokenAddress, Token.abi, wallet);

        await expect(token.interchainTransfer(chains[1].name, wallet.address, amount1, '0x', { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[1].name, wallet.address.toLowerCase(), amount1);

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

        await expect(tokenService.sendToken(tokenId, chains[2].name, wallet.address, amount1, { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[2].name, wallet.address.toLowerCase(), amount1);

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

        await expect(tokenService.sendToken(tokenId, chains[0].name, wallet.address, amount1, { value: 1e6 }))
            .to.emit(tokenService, 'Sending')
            .withArgs(chains[0].name, wallet.address.toLowerCase(), amount1);

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
        const payload = defaultAbiCoder.encode(['address', 'string'], [wallet.address, val]);
        await expect(
            tokenService.callContractWithInterchainToken(tokenId, chains[1].name, chains[1].executable.address, amount1, payload, {
                value: 1e6,
            }),
        )
            .to.emit(tokenService, 'SendingWithData')
            .withArgs(chains[1].name, chains[1].executable.address.toLowerCase(), amount1, wallet.address, payload);

        await relay();

        const [remoteWallet, remoteTokenService] = loadChain(1);
        const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
        const remoteToken = new Contract(remoteTokenAddress, Token.abi, remoteWallet);

        expect(Number(await remoteToken.balanceOf(wallet.address))).to.equal(amount1);
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
        expect(await chains[1].executable.val()).to.equal(val);
    });

    it('Should be deploy some test tokens', async () => {
        const names = ['Token Name 0', 'Token Name 1'];
        const symbols = ['TN0', 'TN1'];
        const decimals = [6, 18];
        const supplies = [1e6, 1e7];
        const tokens = [null, null];

        for (let i = 0; i < 2; i++) {
            const [wallet, tokenService] = loadChain(i);
            tokens[i] = await deployCreate3Contract(chains[i].create3Deployer, wallet, TestToken, 'test-token', [
                chains[i].interchainTokenService,
                names[i],
                symbols[i],
                decimals[i],
                wallet.address,
                supplies[i],
            ]);
            interchainTokenAddress = tokens[i].address;
            const tokenId = await tokenService.getCustomInterchainTokenId(interchainTokenAddress);

            expect(await tokens[i].name()).to.equal(names[i]);
            expect(await tokens[i].symbol()).to.equal(symbols[i]);
            expect(await tokens[i].decimals()).to.equal(decimals[i]);
            expect(await tokens[i].balanceOf(wallet.address)).to.equal(supplies[i]);
            expect(await tokenService.getTokenId(tokens[i].address)).to.equal(tokenId);
            expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokens[i].address);
            expect(await tokenService.isCustomInterchainToken(tokenId)).to.be.true;
        }
    });
    it('Should not be able to register an interchain token', async () => {
        for (let i = 0; i < 2; i++) {
            const [, tokenService] = loadChain(i);
            await expect(tokenService.registerOriginToken(interchainTokenAddress)).to.be.reverted;
        }
    });
    it('Should be able to send some token back and forth', async () => {
        const amounts = [123, 456];

        const tokens = [0, 1].map((i) => {
            const [wallet] = loadChain(i);
            return new Contract(interchainTokenAddress, TestToken.abi, wallet);
        });
        const balances = await Promise.all(tokens.map(async (token) => await token.balanceOf(token.signer.address)));

        const [wallet0, tokenService0] = loadChain(0);
        const [wallet1, tokenService1] = loadChain(0);

        await expect(tokens[0].interchainTransfer(chains[1].name, wallet1.address, amounts[0], '0x', { value: 1e6 }))
            .to.emit(tokenService0, 'Sending')
            .withArgs(chains[1].name, wallet1.address.toLowerCase(), amounts[0]);

        await expect(tokens[1].interchainTransfer(chains[0].name, wallet0.address, amounts[1], '0x', { value: 1e6 }))
            .to.emit(tokenService1, 'Sending')
            .withArgs(chains[0].name, wallet0.address.toLowerCase(), amounts[1]);

        await relay();

        expect(Number(await tokens[0].balanceOf(wallet0.address))).to.equal(balances[0] - amounts[0] + amounts[1]);
        expect(Number(await tokens[1].balanceOf(wallet1.address))).to.equal(balances[1] - amounts[1] + amounts[0]);
    });
});
