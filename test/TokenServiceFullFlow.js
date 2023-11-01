'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256, hexlify } = ethers.utils;
const { Contract, Wallet } = ethers;

const StandardizedToken = require('../artifacts/contracts/token-implementations/StandardizedToken.sol/StandardizedToken.json');
const ITokenManager = require('../artifacts/contracts/interfaces/ITokenManager.sol/ITokenManager.json');
const ITokenManagerMintBurn = require('../artifacts/contracts/interfaces/ITokenManagerMintBurn.sol/ITokenManagerMintBurn.json');

const { getRandomBytes32, expectRevert } = require('./utils');
const { deployAll, deployContract } = require('../scripts/deploy');

const SELECTOR_RECEIVE_TOKEN = 1;
const SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
const SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

const DISTRIBUTOR_ROLE = 0;

const MINT_BURN = 0;
const LOCK_UNLOCK = 2;

describe('Interchain Token Service Full Flow', () => {
    let wallet;
    let service, gateway, gasService, tokenManager, tokenId;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const otherChains = ['chain 1', 'chain 2'];
    const decimals = 18;

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService] = await deployAll(wallet, 'Test', otherChains);
    });

    describe('Full canonical token registration, remote deployment and token send', async () => {
        let token;
        const gasValues = [1234, 5678];
        const tokenCap = BigInt(1e18);

        before(async () => {
            // The below is used to deploy a token, but any ERC20 can be used instead.
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);
            tokenId = await service.getCanonicalTokenId(token.address);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
            tokenManager = new Contract(tokenManagerAddress, ITokenManager.abi, wallet);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const tx1 = await service.populateTransaction.registerCanonicalToken(token.address);
            const data = [tx1.data];
            let value = 0;

            for (const i in otherChains) {
                const tx = await service.populateTransaction.deployRemoteCanonicalToken(tokenId, otherChains[i], gasValues[i]);
                data.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, name, symbol, decimals, '0x', '0x', 0, '0x'],
            );
            const expectedTokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await expect(service.multicall(data, { value }))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, LOCK_UNLOCK, params)
                .and.to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, '0x', otherChains[0], gasValues[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, '0x', otherChains[1], gasValues[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload);
        });

        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [SELECTOR_RECEIVE_TOKEN, tokenId, hexlify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            await expect(token.approve(tokenManager.address, amount))
                .to.emit(token, 'Approval')
                .withArgs(wallet.address, tokenManager.address, amount);

            await expect(tokenManager.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, tokenManager.address, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'TokenSent')
                .withArgs(tokenId, destChain, destAddress, amount);
        });

        // For this test the token must be a standardized token (or a distributable token in general)
        it('Should be able to change the token distributor', async () => {
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferDistributorship(newAddress))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(newAddress, 1 << DISTRIBUTOR_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
        });
    });

    describe('Full standardized token registration, remote deployment and token send', async () => {
        let token;
        let tokenId;
        const salt = getRandomBytes32();
        const gasValues = [1234, 5678];
        const tokenCap = BigInt(1e18);

        before(async () => {
            tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            token = new Contract(tokenAddress, StandardizedToken.abi, wallet);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            tokenManager = new Contract(tokenManagerAddress, ITokenManager.abi, wallet);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const tx1 = await service.populateTransaction.deployAndRegisterStandardizedToken(
                salt,
                name,
                symbol,
                decimals,
                tokenCap,
                wallet.address,
            );
            const data = [tx1.data];
            let value = 0;

            for (const i in otherChains) {
                const tx = await service.populateTransaction.deployAndRegisterRemoteStandardizedToken(
                    salt,
                    name,
                    symbol,
                    decimals,
                    '0x',
                    '0x',
                    0,
                    wallet.address,
                    otherChains[i],
                    gasValues[i],
                );
                data.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, name, symbol, decimals, '0x', '0x', 0, wallet.address],
            );
            const tx = service.multicall(data, { value });

            const expectedTokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const expectedTokenAddress = await service.getStandardizedTokenAddress(tokenId);
            await expect(tx)
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, expectedTokenAddress, wallet.address, name, symbol, decimals, tokenCap, wallet.address)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params)
                .and.to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, wallet.address.toLowerCase(), otherChains[0], gasValues[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, wallet.address.toLowerCase(), otherChains[1], gasValues[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload);
        });

        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [SELECTOR_RECEIVE_TOKEN, tokenId, hexlify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            await expect(tokenManager.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'TokenSent')
                .withArgs(tokenId, destChain, destAddress, amount);
        });

        // For this test the token must be a standardized token (or a distributable token in general)
        // TODO no token is deployed so how will mint and burn work?
        it('Should be able to change the token distributor', async () => {
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferDistributorship(newAddress))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(newAddress, 1 << DISTRIBUTOR_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
        });
    });

    describe('Full pre-existing token registration and token send', async () => {
        let token;
        const otherChains = ['chain 1', 'chain 2'];
        const gasValues = [1234, 5678];
        const tokenCap = BigInt(1e18);
        const salt = keccak256('0x697858');

        before(async () => {
            // The below is used to deploy a token, but any ERC20 that has a mint capability can be used instead.
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);

            tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
            tokenManager = new Contract(tokenManagerAddress, ITokenManager.abi, wallet);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const implAddress = await service.getImplementation(MINT_BURN);
            const impl = new Contract(implAddress, ITokenManagerMintBurn.abi, wallet);
            const params = await impl.getParams(wallet.address, token.address);
            const tx1 = await service.populateTransaction.deployCustomTokenManager(salt, MINT_BURN, params);
            const data = [tx1.data];
            let value = 0;

            for (const i in otherChains) {
                const tx = await service.populateTransaction.deployRemoteCustomTokenManager(
                    salt,
                    otherChains[i],
                    MINT_BURN,
                    params,
                    gasValues[i],
                );
                data.push(tx.data);
                value += gasValues[i];
            }

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, MINT_BURN, params],
            );
            const expectedTokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await expect(service.multicall(data, { value }))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params)
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, otherChains[0], gasValues[0], MINT_BURN, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, otherChains[1], gasValues[1], MINT_BURN, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload);
        });

        // For this test the token must be a standardized token (or a distributable token in general)
        it('Should be able to change the token distributor', async () => {
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferDistributorship(tokenManager.address))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(tokenManager.address, 1 << DISTRIBUTOR_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
        });

        // In order to be able to receive tokens the distributorship should be changed on other chains as well.
        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [SELECTOR_RECEIVE_TOKEN, tokenId, hexlify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            await expect(tokenManager.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'TokenSent')
                .withArgs(tokenId, destChain, destAddress, amount);
        });
    });
});
