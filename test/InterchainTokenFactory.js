'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const { defaultAbiCoder, keccak256 } = ethers.utils;
const {
    getContractAt,
    Wallet,
    constants: { AddressZero },
} = ethers;

const { deployAll, deployContract } = require('../scripts/deploy');
const { getRandomBytes32 } = require('./utils');

// const MESSAGE_TYPE_INTERCHAIN_TRANSFER_WITH_DATA = 1;
const MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 2;
// const MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 3;

const LOCK_UNLOCK = 2;
const MINT_BURN = 0;

const DISTRIBUTOR_ROLE = 0;
const OPERATOR_ROLE = 1;
const FLOW_LIMITER_ROLE = 2;

describe('InterchainTokenFactory', () => {
    let wallet;
    let service, gateway, gasService, tokenFactory;
    const chainName = 'Test';
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService] = await deployAll(wallet, chainName, [destinationChain]);

        tokenFactory = await deployContract(wallet, 'InterchainTokenFactory', [service.address]);
        const proxy = await deployContract(wallet, 'InterchainTokenFactoryProxy', [tokenFactory.address, wallet.address]);
        const factory = await ethers.getContractFactory('InterchainTokenFactory', wallet);
        tokenFactory = factory.attach(proxy.address);
    });

    describe('Canonical Interchain Token Factory', async () => {
        let token, tokenId, tokenManagerAddress;
        const tokenCap = BigInt(1e18);

        async function deployToken() {
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);
            tokenId = await tokenFactory.canonicalInterchainTokenId(token.address);
            tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
        }

        it('Should register a token', async () => {
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
        });

        it('Should initiate a remote interchain token deployment', async () => {
            const gasValue = 1234;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await expect(
                tokenFactory.deployRemoteCanonicalInterchainToken(chainName, token.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should transfer some tokens to the factory', async () => {
            const amount = 123456;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await token.approve(tokenFactory.address, amount).then((tx) => tx.wait());

            await expect(tokenFactory.tokenTransferFrom(tokenId, amount))
                .to.emit(token, 'Transfer')
                .withArgs(wallet.address, tokenFactory.address, amount);
        });

        it('Should approve some tokens from the factory to the token manager', async () => {
            const amount = 123456;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            tokenManagerAddress = await service.validTokenManagerAddress(tokenId);

            await expect(tokenFactory.tokenApprove(tokenId, amount))
                .to.emit(token, 'Approval')
                .withArgs(tokenFactory.address, tokenManagerAddress, amount);
        });

        it('Should transfer some tokens through the factory as the deployer', async () => {
            const amount = 123456;
            const destinationAddress = '0x57689403';
            const gasValue = 45960;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await token.approve(tokenFactory.address, amount).then((tx) => tx.wait());

            tokenManagerAddress = await service.validTokenManagerAddress(tokenId);

            const txs = [];

            txs.push(await tokenFactory.populateTransaction.tokenTransferFrom(tokenId, amount));
            txs.push(await tokenFactory.populateTransaction.tokenApprove(tokenId, amount));
            txs.push(
                await tokenFactory.populateTransaction.interchainTransfer(tokenId, destinationChain, destinationAddress, amount, gasValue),
            );

            await expect(
                tokenFactory.multicall(
                    txs.map((tx) => tx.data),
                    { value: gasValue },
                ),
            )
                .to.emit(token, 'Transfer')
                .withArgs(wallet.address, tokenFactory.address, amount)
                .and.to.emit(token, 'Approval')
                .withArgs(tokenFactory.address, tokenManagerAddress, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(tokenFactory.address, tokenManagerAddress, amount)
                .and.to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, destinationChain, destinationAddress, amount);
        });
    });

    describe('Interchain Token Factory', async () => {
        let tokenId;
        const mintAmount = 1234;
        const distributor = new Wallet(getRandomBytes32()).address;

        it('Should register a token', async () => {
            const salt = keccak256('0x');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, distributor))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenFactory.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(distributor, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(distributor, 1 << OPERATOR_ROLE)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(distributor, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            await expect(tokenFactory.interchainTransfer(tokenId, '', distributor, mintAmount, 0))
                .to.emit(token, 'Transfer')
                .withArgs(tokenFactory.address, distributor, mintAmount);

            expect(await token.balanceOf(tokenFactory.address)).to.equal(0);
            expect(await token.balanceOf(distributor)).to.equal(mintAmount);
        });

        it('Should initiate a remote interchain token deployment with the same distributor', async () => {
            const gasValue = 1234;
            const mintAmount = 5678;

            const salt = keccak256('0x12');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenFactory.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, wallet.address.toLowerCase()],
            );

            await expect(
                tokenFactory.deployRemoteInterchainToken(chainName, salt, wallet.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should initiate a remote interchain token deployment without the same distributor', async () => {
            const gasValue = 1234;

            const salt = keccak256('0x1245');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenFactory.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );

            await expect(
                tokenFactory.deployRemoteInterchainToken(chainName, salt, AddressZero, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });
    });
});
