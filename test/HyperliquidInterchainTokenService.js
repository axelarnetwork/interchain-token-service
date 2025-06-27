'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');
const { getRandomBytes32 } = require('./utils');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

describe('HyperliquidInterchainTokenService', () => {
    let service, gateway, gasService, tokenFactory;
    let tokenManagerDeployer, interchainTokenDeployer, tokenManager, tokenHandler;
    let wallet, otherWallet, operator, nonOperator;
    let testToken, tokenId;

    before(async () => {
        [wallet, otherWallet, operator, nonOperator] = await ethers.getSigners();

        // Deploy the full Hyperliquid setup
        const deployment = await deployAll(
            wallet,
            'hyperliquid',
            ITS_HUB_ADDRESS,
            [],
            'HyperliquidInterchainTokenService',
            'HyperliquidInterchainTokenServiceFactory',
        );

        service = deployment.service;
        gateway = deployment.gateway;
        gasService = deployment.gasService;
        tokenFactory = deployment.tokenFactory;
        tokenManagerDeployer = deployment.tokenManagerDeployer;
        interchainTokenDeployer = deployment.interchainTokenDeployer;
        tokenManager = deployment.tokenManager;
        tokenHandler = deployment.tokenHandler;

        // Set up operator role for testing - use the correct role ID
        await service.transferOperatorship(operator.address);
    });

    describe('Constructor and Setup', () => {
        it('should deploy with correct parameters', async () => {
            expect(await service.tokenManagerDeployer()).to.equal(tokenManagerDeployer.address);
            expect(await service.interchainTokenDeployer()).to.equal(interchainTokenDeployer.address);
            expect(await service.gateway()).to.equal(gateway.address);
            expect(await service.gasService()).to.equal(gasService.address);
            expect(await service.interchainTokenFactory()).to.equal(tokenFactory.address);
            expect(await service.tokenManager()).to.equal(tokenManager.address);
            expect(await service.tokenHandler()).to.equal(tokenHandler.address);
        });

        it('should have correct operator setup', async () => {
            // Check if the operator has the correct role
            expect(await service.isOperator(operator.address)).to.be.true;
            expect(await service.owner()).to.equal(wallet.address);
        });
    });

    describe('updateTokenDeployer', () => {
        beforeEach(async () => {
            // Deploy a test token and register it with a token manager
            const salt = getRandomBytes32();
            tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            // Deploy a test Hyperliquid token
            testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            testToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, tokenId);

            // Register the token with a token manager using the factory
            await tokenFactory.registerCustomToken(salt, testToken.address, 1, wallet.address); // MINT_BURN type
        });

        it('should allow operator to update token deployer', async () => {
            const newDeployer = otherWallet.address;

            // Call updateTokenDeployer as operator
            await expect(service.connect(operator).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, operator.address);

            // Verify the deployer was updated on the token
            expect(await testToken.deployer()).to.equal(newDeployer);
        });

        it('should allow owner to update token deployer', async () => {
            const newDeployer = otherWallet.address;

            // Call updateTokenDeployer as owner
            await expect(service.connect(wallet).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, wallet.address);

            // Verify the deployer was updated on the token
            expect(await testToken.deployer()).to.equal(newDeployer);
        });

        it('should revert when called by non-operator and non-owner', async () => {
            const newDeployer = otherWallet.address;

            await expect(service.connect(nonOperator).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should revert when token manager does not exist', async () => {
            const nonExistentTokenId = getRandomBytes32();
            const newDeployer = otherWallet.address;

            await expect(service.connect(operator).updateTokenDeployer(nonExistentTokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'TokenManagerDoesNotExist',
            );
        });

        it('should handle zero address for new deployer', async () => {
            const newDeployer = ethers.constants.AddressZero;

            // Should work with zero address
            await expect(service.connect(operator).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, operator.address);

            // Verify the deployer was updated to zero address
            expect(await testToken.deployer()).to.equal(newDeployer);
        });

        it('should emit TokenDeployerUpdated event with correct parameters', async () => {
            const newDeployer = otherWallet.address;

            const tx = await service.connect(operator).updateTokenDeployer(tokenId, newDeployer);
            const receipt = await tx.wait();

            // Find the TokenDeployerUpdated event
            const event = receipt.events?.find((e) => e.event === 'TokenDeployerUpdated');
            expect(event).to.not.be.undefined;
            expect(event.args.token).to.equal(testToken.address);
            expect(event.args.newDeployer).to.equal(newDeployer);
            expect(event.args.operator).to.equal(operator.address);
        });

        it('should allow multiple updates to the same token', async () => {
            const deployer1 = otherWallet.address;
            const deployer2 = nonOperator.address;

            // First update
            await service.connect(operator).updateTokenDeployer(tokenId, deployer1);
            expect(await testToken.deployer()).to.equal(deployer1);

            // Second update
            await service.connect(operator).updateTokenDeployer(tokenId, deployer2);
            expect(await testToken.deployer()).to.equal(deployer2);
        });

        it('should work with different token managers', async () => {
            // Deploy a second token and token manager
            const salt2 = getRandomBytes32();
            const tokenId2 = await tokenFactory.linkedTokenId(wallet.address, salt2);

            const testToken2 = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken2 = await testToken2.deploy('TestToken2', 'TEST2', 18, service.address, tokenId2);

            await tokenFactory.registerCustomToken(salt2, deployedToken2.address, 1, wallet.address);

            const newDeployer = otherWallet.address;

            // Update both tokens
            await service.connect(operator).updateTokenDeployer(tokenId, newDeployer);
            await service.connect(operator).updateTokenDeployer(tokenId2, newDeployer);

            expect(await testToken.deployer()).to.equal(newDeployer);
            expect(await deployedToken2.deployer()).to.equal(newDeployer);
        });
    });

    describe('Integration Tests', () => {
        it('should work with deployed Hyperliquid token through factory', async () => {
            // Deploy a complete setup with Hyperliquid token through the factory
            const salt = getRandomBytes32();
            const testTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            // Deploy a test Hyperliquid token
            const testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, testTokenId);

            // Register with token manager using factory
            await tokenFactory.registerCustomToken(salt, deployedToken.address, 1, wallet.address);

            // Test that the service can update the deployer
            const newDeployer = otherWallet.address;
            await service.connect(operator).updateTokenDeployer(testTokenId, newDeployer);

            expect(await deployedToken.deployer()).to.equal(newDeployer);
        });

        it('should maintain proper state after deployer update', async () => {
            const salt = getRandomBytes32();
            const testTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            // Deploy and register token
            const testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, testTokenId);
            await tokenFactory.registerCustomToken(salt, deployedToken.address, 1, wallet.address);

            // Verify initial state
            expect(await deployedToken.deployer()).to.equal(ethers.constants.AddressZero);

            // Update deployer
            const newDeployer = otherWallet.address;
            await service.connect(operator).updateTokenDeployer(testTokenId, newDeployer);

            // Verify updated state
            expect(await deployedToken.deployer()).to.equal(newDeployer);

            // Verify token manager still exists and is accessible
            const tokenManagerAddress = await service.tokenManagerAddress(testTokenId);
            expect(tokenManagerAddress).to.not.equal(ethers.constants.AddressZero);
        });
    });

    describe('Error Handling', () => {
        it('should handle invalid tokenId gracefully', async () => {
            const invalidTokenId = '0x0000000000000000000000000000000000000000000000000000000000000000';
            const newDeployer = otherWallet.address;

            await expect(service.connect(operator).updateTokenDeployer(invalidTokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'TokenManagerDoesNotExist',
            );
        });

        it('should handle edge cases with deployer addresses', async () => {
            const salt = getRandomBytes32();
            const testTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            const testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, testTokenId);
            await tokenFactory.registerCustomToken(salt, deployedToken.address, 1, wallet.address);

            // Test various edge cases for deployer addresses
            const edgeCases = [
                ethers.constants.AddressZero,
                '0x0000000000000000000000000000000000000001',
                '0xffffffffffffffffffffffffffffffffffffffff',
            ];

            for (const edgeCase of edgeCases) {
                await service.connect(operator).updateTokenDeployer(testTokenId, edgeCase);
                expect(ethers.utils.getAddress(await deployedToken.deployer())).to.equal(ethers.utils.getAddress(edgeCase));
            }
        });
    });

    describe('Permission Tests', () => {
        it('should respect operator permissions', async () => {
            const salt = getRandomBytes32();
            const testTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            const testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, testTokenId);
            await tokenFactory.registerCustomToken(salt, deployedToken.address, 1, wallet.address);

            const newDeployer = otherWallet.address;

            // Should work for operator
            await service.connect(operator).updateTokenDeployer(testTokenId, newDeployer);
            expect(await deployedToken.deployer()).to.equal(newDeployer);

            // Should work for owner
            const newDeployer2 = nonOperator.address;
            await service.connect(wallet).updateTokenDeployer(testTokenId, newDeployer2);
            expect(await deployedToken.deployer()).to.equal(newDeployer2);

            // Should fail for non-operator
            const newDeployer3 = ethers.Wallet.createRandom().address;
            await expect(service.connect(nonOperator).updateTokenDeployer(testTokenId, newDeployer3)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });
    });
});
