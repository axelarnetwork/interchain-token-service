'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { defaultAbiCoder, keccak256 } = ethers.utils;
const {
    Contract,
    Wallet,
    constants: { AddressZero },
} = ethers;

const ITokenManager = require('../artifacts/contracts/interfaces/ITokenManager.sol/ITokenManager.json');
const IStandardizedToken = require('../artifacts/contracts/interfaces/IStandardizedToken.sol/IStandardizedToken.json');

const { deployAll, deployContract } = require('../scripts/deploy');
const { getRandomBytes32 } = require('./utils');

// const MESSAGE_TYPE_SEND_TOKEN_WITH_DATA = 2;
// const MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 3;
const MESSAGE_TYPE_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

const LOCK_UNLOCK = 2;
const MINT_BURN = 0;

const DISTRIBUTOR_ROLE = 0;
const OPERATOR_ROLE = 1;
const FLOW_LIMITER_ROLE = 2;

describe('Token Registrars', () => {
    let wallet;
    let service, gateway, gasService, tokenRegistrar;
    const chainName = 'Test';
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService] = await deployAll(wallet, chainName, [destinationChain]);

        tokenRegistrar = await deployContract(wallet, 'TokenRegistrar', [service.address]);
        const proxy = await deployContract(wallet, 'TokenRegistrarProxy', [tokenRegistrar.address, wallet.address]);
        const factory = await ethers.getContractFactory('TokenRegistrar', wallet);
        tokenRegistrar = factory.attach(proxy.address);
    });

    describe('Canonical Token Registrar', async () => {
        let token, tokenId, tokenManagerAddress;
        const tokenCap = BigInt(1e18);

        async function deployToken() {
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);
            tokenId = await tokenRegistrar.canonicalTokenId(token.address);
            tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
        }

        it('Should register a token', async () => {
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
        });

        it('Should initiate a remote standardized token deployment', async () => {
            const gasValue = 1234;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, name, symbol, decimals, '0x', '0x'],
            );

            await expect(tokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await expect(
                tokenRegistrar.deployRemoteCanonicalToken(chainName, token.address, destinationChain, gasValue, { value: gasValue }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should transfer some tokens to the registrar', async () => {
            const amount = 123456;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await token.approve(tokenRegistrar.address, amount).then((tx) => tx.wait());

            await expect(
                 tokenRegistrar.tokenTransferFrom(tokenId, amount),
             )
                 .to.emit(token, 'Transfer')
                 .withArgs(wallet.address, tokenRegistrar.address, amount);
        });


        it('Should approve some tokens from the registrar to the token manager', async () => {
            const amount = 123456;
            
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            tokenManagerAddress = await service.validTokenManagerAddress(tokenId);

            await expect(
                 tokenRegistrar.tokenApprove(tokenId, amount),
             )
                 .to.emit(token, 'Approval')
                 .withArgs(tokenRegistrar.address, tokenManagerAddress, amount)
        });

        it('Should transfer some tokens through the registrar as the deployer', async () => {
            const amount = 123456;
            const destinationAddress = '0x57689403';
            const gasValue = 45960;
            
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await token.approve(tokenRegistrar.address, amount).then((tx) => tx.wait());

            tokenManagerAddress = await service.validTokenManagerAddress(tokenId);

            const txs = [];

            txs.push(await tokenRegistrar.populateTransaction.tokenTransferFrom(tokenId, amount));
            txs.push(await tokenRegistrar.populateTransaction.tokenApprove(tokenId, amount));
            txs.push(await tokenRegistrar.populateTransaction.interchainTransfer(tokenId, destinationChain, destinationAddress, amount, gasValue));

            await expect(
                 tokenRegistrar.multicall(txs.map(tx => tx.data), {value: gasValue}),
             )
                .to.emit(token, 'Transfer')
                .withArgs(wallet.address, tokenRegistrar.address, amount)
                .and.to.emit(token, 'Approval')
                .withArgs(tokenRegistrar.address, tokenManagerAddress, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(tokenRegistrar.address, tokenManagerAddress, amount)
                .and.to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, destinationChain, destinationAddress, amount)
        });
    });

    describe('Standardized Token Registrar', async () => {
        let tokenId;
        const mintAmount = 1234;
        const distributor = new Wallet(getRandomBytes32()).address;
        const operator = new Wallet(getRandomBytes32()).address;

        it('Should register a token', async () => {
            const salt = keccak256('0x');
            tokenId = await tokenRegistrar.standardizedTokenId(wallet.address, salt);
            const tokenAddress = await tokenRegistrar.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, tokenAddress]);
            const tokenManager = new Contract(await service.tokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IStandardizedToken.abi, wallet);

            await expect(tokenRegistrar.deployInterchainToken(salt, name, symbol, decimals, mintAmount, distributor, operator))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenRegistrar.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenRegistrar.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(operator, (1 << OPERATOR_ROLE) | (1 << FLOW_LIMITER_ROLE))
                .and.to.emit(token, 'RolesAdded')
                .withArgs(distributor, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenRegistrar.address, 1 << DISTRIBUTOR_ROLE);

            await expect(tokenRegistrar.interchainTransfer(tokenId, '', distributor, mintAmount, 0))
                .to.emit(token, 'Transfer')
                .withArgs(tokenRegistrar.address, distributor, mintAmount);

            expect(await token.balanceOf(tokenRegistrar.address)).to.equal(0);
            expect(await token.balanceOf(distributor)).to.equal(mintAmount);
        });

        it('Should initiate a remote standardized token deployment with the same distributor', async () => {
            const gasValue = 1234;
            const mintAmount = 5678;

            const salt = keccak256('0x12');
            tokenId = await tokenRegistrar.standardizedTokenId(wallet.address, salt);
            const tokenAddress = await tokenRegistrar.interchainTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
            const tokenManager = new Contract(await service.tokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IStandardizedToken.abi, wallet);

            await expect(tokenRegistrar.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenRegistrar.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenRegistrar.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenRegistrar.address, 1 << DISTRIBUTOR_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
                [
                    MESSAGE_TYPE_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    name,
                    symbol,
                    decimals,
                    wallet.address.toLowerCase(),
                    wallet.address.toLowerCase(),
                ],
            );

            await expect(
                tokenRegistrar.deployRemoteInterchainToken(chainName, salt, wallet.address, wallet.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should initiate a remote standardized token deployment without the same distributor', async () => {
            const gasValue = 1234;

            const salt = keccak256('0x1245');
            tokenId = await tokenRegistrar.standardizedTokenId(wallet.address, salt);
            const tokenAddress = await tokenRegistrar.interchainTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
            const tokenManager = new Contract(await service.tokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IStandardizedToken.abi, wallet);

            await expect(tokenRegistrar.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenRegistrar.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenRegistrar.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenRegistrar.address, 1 << DISTRIBUTOR_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, name, symbol, decimals, '0x', wallet.address],
            );

            await expect(
                tokenRegistrar.deployRemoteInterchainToken(chainName, salt, AddressZero, wallet.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });
    });
});
