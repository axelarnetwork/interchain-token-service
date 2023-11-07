'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256, hexlify, arrayify } = ethers.utils;
const { getContractAt, Wallet } = ethers;

const { getRandomBytes32, expectRevert } = require('./utils');
const { deployAll, deployContract } = require('../scripts/deploy');

const MESSAGE_TYPE_INTERCHAIN_TRANSFER = 0;
const MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 2;
const MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 3;

const DISTRIBUTOR_ROLE = 0;

const MINT_BURN = 0;
const LOCK_UNLOCK = 2;

describe('Interchain Token Service Full Flow', () => {
    let wallet;
    let service, gateway, gasService, tokenManager, factory, tokenId;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const otherChains = ['chain 1', 'chain 2'];
    const decimals = 6;
    const chainName = 'Test';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService, factory] = await deployAll(wallet, chainName, otherChains);
    });

    /**
     * This test deploys Canonical Interchain tokens for a pre-existing token on remote chains via the InterchainTokenFactory and multicall.
     * Canonical tokens are registered under Lock/Unlock token manager on local chain, and mint/burn on remote chains.
     * They can be deployed to remote chains by anyone, and don't depend on a deployer address/salt.
     * - If pre-mint is needed, make an ERC20 approval to the Factory contract
     * - Register pre-existing token as Canonical
     * - Deploy Canonical Interchain token to each remote chain via the factory
     * - Transfer pre-mint amount to the Factory contract
     * - Approve ITS for pre-mint amount
     * - Transfer per chain pre-mint amount to the user on each remote chain
     * - Transfer tokens via the token manager between chains after deployment
     */
    describe('Canonical Interchain Token', async () => {
        let token;
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;
        const transferAmount = 1e6;

        before(async () => {
            // Any ERC20 can be used here
            token = await deployContract(wallet, 'TestMintableBurnableERC20', [name, symbol, decimals]);
            await token.mint(wallet.address, tokenCap + transferAmount).then((tx) => tx.wait());
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const mintAmount = Math.floor(tokenCap / otherChains.length);
            const totalMint = mintAmount * otherChains.length;

            await token.approve(factory.address, totalMint).then((tx) => tx.wait());

            tokenId = await factory.canonicalInterchainTokenId(token.address);

            let tx = await factory.populateTransaction.registerCanonicalInterchainToken(token.address);
            const calls = [tx.data];
            let value = 0;

            for (const i in otherChains) {
                tx = await factory.populateTransaction.deployRemoteCanonicalInterchainToken(
                    chainName,
                    token.address,
                    otherChains[i],
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            // Transfer total mint amount to the factory contract
            tx = await factory.populateTransaction.tokenTransferFrom(tokenId, totalMint);
            calls.push(tx.data);

            // Transfer tokens from factory contract to the user on remote chains.
            for (const i in otherChains) {
                tx = await factory.populateTransaction.approveAndInterchainTransfer(
                    tokenId,
                    otherChains[i],
                    wallet.address,
                    mintAmount,
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await factory.multicall(calls, { value });

            await expect(multicall)
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, LOCK_UNLOCK, params)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, factory.address, totalMint)
                .and.to.emit(token, 'Approval')
                .withArgs(factory.address, expectedTokenManagerAddress, mintAmount)
                .and.to.emit(token, 'Transfer')
                .withArgs(factory.address, expectedTokenManagerAddress, mintAmount)
                .and.to.emit(token, 'Approval')
                .withArgs(factory.address, expectedTokenManagerAddress, mintAmount)
                .and.to.emit(token, 'Transfer')
                .withArgs(factory.address, expectedTokenManagerAddress, mintAmount);
        });

        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, arrayify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

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
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, destChain, destAddress, amount);
        });
    });

    /**
     * This test deploys brand new Interchain tokens to all chains via the InterchainTokenFactory and multicall:
     * - Deploy new Interchain token on local chain with a pre-mint (to the factory contract) via the factory
     * - Deploy new Interchain token to each remote chain via the factory
     * - Transfer initial amount to the user on local chain
     * - Transfer initial amount to the user on each remote chain
     * - Transfer tokens via the token manager between chains after deployment
     * - Transfers mint/burn role from original deployer wallet to another address
     */
    describe('New Interchain token', async () => {
        let token;
        let tokenId;
        const salt = getRandomBytes32();
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;

        before(async () => {
            tokenId = await factory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            token = await getContractAt('InterchainToken', tokenAddress, wallet);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const mintAmount = Math.floor(tokenCap / (otherChains.length + 1));
            const totalMint = mintAmount * (otherChains.length + 1);

            // Deploy a new Interchain token on the local chain.
            // The initial mint occurs on the factory contract, so it can be moved to other chains within the same multicall.
            let tx = await factory.populateTransaction.deployInterchainToken(salt, name, symbol, decimals, totalMint, wallet.address);
            const calls = [tx.data];
            let value = 0;

            // Deploy a linked Interchain token to remote chains.
            for (const i in otherChains) {
                tx = await factory.populateTransaction.deployRemoteInterchainToken(
                    chainName,
                    salt,
                    wallet.address,
                    otherChains[i],
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            // Transfer tokens from factory contract to the user on local chain.
            tx = await factory.populateTransaction.interchainTransfer(tokenId, '', wallet.address, mintAmount, 0);
            calls.push(tx.data);

            // Transfer tokens from factory contract to the user on remote chains.
            for (const i in otherChains) {
                tx = await factory.populateTransaction.interchainTransfer(
                    tokenId,
                    otherChains[i],
                    wallet.address,
                    mintAmount,
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], [factory.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, wallet.address],
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const expectedTokenAddress = await service.interchainTokenAddress(tokenId);

            const multicall = await factory.multicall(calls, { value });
            await expect(multicall)
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectedTokenAddress, factory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, factory.address, totalMint)
                .and.to.emit(token, 'Transfer')
                .withArgs(factory.address, wallet.address, mintAmount)
                .and.to.emit(token, 'Transfer')
                .withArgs(factory.address, AddressZero, mintAmount);

            // Only tokens minted for the local chain should be left, remaining should be burned.
            expect(await token.balanceOf(wallet.address)).to.equal(mintAmount);
        });

        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

            await expect(tokenManager.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, destChain, destAddress, amount);
        });

        /**
         * Change the distributor/minter to another address
         */
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

    /**
     * This test creates a token link between pre-existing tokens by giving mint/burn permission to a linked token manager.
     * - Deploy a normal mint/burn ERC20 registered with an owner
     * - Deploy a mint/burn token manager for the token on all chains
     * - Transfer mint/burn permission (distributor role) to the token manager
     * - Transfer tokens via the token manager between chains
     */
    describe('Pre-existing Token as Mint/Burn', async () => {
        let token;
        const otherChains = ['chain 1', 'chain 2'];
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;
        const salt = keccak256('0x697858');

        before(async () => {
            token = await deployContract(wallet, 'TestMintableBurnableERC20', [name, symbol, decimals]);

            tokenId = await service.interchainTokenId(wallet.address, salt);
            await (await token.mint(wallet.address, tokenCap)).wait();
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const implAddress = await service.tokenManagerImplementation(MINT_BURN);
            const impl = await getContractAt('TokenManagerMintBurn', implAddress, wallet);
            const params = await impl.params(wallet.address, token.address);
            let tx = await service.populateTransaction.deployTokenManager(salt, '', MINT_BURN, params, 0);
            const calls = [tx.data];
            let value = 0;

            for (const i in otherChains) {
                tx = await service.populateTransaction.deployTokenManager(salt, otherChains[i], MINT_BURN, params, gasValues[i]);
                calls.push(tx.data);
                value += gasValues[i];
            }

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER, tokenId, MINT_BURN, params],
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
            await expect(service.multicall(calls, { value }))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params)
                .and.to.emit(service, 'TokenManagerDeploymentStarted')
                .withArgs(tokenId, otherChains[0], MINT_BURN, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[0], service.address, keccak256(payload), payload)
                .and.to.emit(service, 'TokenManagerDeploymentStarted')
                .withArgs(tokenId, otherChains[1], MINT_BURN, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, otherChains[1], service.address, keccak256(payload), payload);
        });

        /**
         * Transfer the distributor to associated the token manager on all chains to allow ITS to mint/burn
         */
        it('Should be able to change the token distributor', async () => {
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferDistributorship(tokenManagerAddress))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << DISTRIBUTOR_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(tokenManagerAddress, 1 << DISTRIBUTOR_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                DISTRIBUTOR_ROLE,
            ]);
        });

        /**
         * Send an interchain transfer via the token manager. To receive the tokens, the receiving token manager
         * also needs to have the mint/burn permission.
         */
        it('Should send some token to another chain', async () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount],
            );
            const payloadHash = keccak256(payload);

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

            await expect(tokenManager.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destChain, service.address, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, destChain, destAddress, amount);
        });
    });
});
