'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const { getRandomBytes32 } = require('./utils');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

describe('Hyperliquid Interchain Token Service', () => {
    let wallet, otherWallet, operator, nonOperator;
    let service, tokenFactory;
    let testToken, tokenId;

    before(async () => {
        [wallet, otherWallet, operator, nonOperator] = await ethers.getSigners();

        const deployment = await deployAll(
            wallet,
            'hyperliquid',
            ITS_HUB_ADDRESS,
            [],
            'HyperliquidInterchainTokenService',
            'HyperliquidInterchainTokenServiceFactory',
        );

        service = deployment.service;
        tokenFactory = deployment.tokenFactory;

        await service.transferOperatorship(operator.address);
    });

    describe('Hyperliquid Interchain Token Service Update Token Deployer', () => {
        beforeEach(async () => {
            const salt = getRandomBytes32();
            tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            testToken = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            testToken = await testToken.deploy('TestToken', 'TEST', 18, service.address, tokenId);

            await tokenFactory.registerCustomToken(salt, testToken.address, 1, wallet.address);
        });

        it('should handle authorization and update token deployer', async () => {
            const newDeployer = otherWallet.address;

            await expect(service.connect(operator).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, operator.address);

            expect(await testToken.deployer()).to.equal(newDeployer);

            const newDeployer2 = nonOperator.address;
            await expect(service.connect(wallet).updateTokenDeployer(tokenId, newDeployer2))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer2, wallet.address);

            expect(await testToken.deployer()).to.equal(newDeployer2);

            await expect(service.connect(nonOperator).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should revert if token manager does not exist', async () => {
            const nonExistentTokenId = getRandomBytes32();
            const newDeployer = otherWallet.address;

            await expect(service.connect(operator).updateTokenDeployer(nonExistentTokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'TokenManagerDoesNotExist',
            );
        });

        it('should revert if token does not support Hyperliquid interface', async () => {
            const salt = getRandomBytes32();
            const standardTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);

            // Deploy a standard token that doesn't implement IHyperliquidDeployer
            const standardToken = await ethers.getContractFactory('TestInterchainTokenStandard', wallet);
            const deployedStandardToken = await standardToken.deploy('StandardToken', 'STD', 18, service.address, standardTokenId);

            await tokenFactory.registerCustomToken(salt, deployedStandardToken.address, 1, wallet.address);

            const newDeployer = otherWallet.address;

            await expect(service.connect(operator).updateTokenDeployer(standardTokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'TokenDoesNotSupportHyperliquidInterface',
            ).withArgs(deployedStandardToken.address);
        });

        it('should emit TokenDeployerUpdated event with correct parameters', async () => {
            const newDeployer = otherWallet.address;

            const tx = await service.connect(operator).updateTokenDeployer(tokenId, newDeployer);
            const receipt = await tx.wait();

            const event = receipt.events?.find((e) => e.event === 'TokenDeployerUpdated');
            expect(event).to.not.be.undefined;
            expect(event.args.token).to.equal(testToken.address);
            expect(event.args.newDeployer).to.equal(newDeployer);
            expect(event.args.operator).to.equal(operator.address);
        });

        it('should handle multiple updates and different token managers', async () => {
            const deployer1 = otherWallet.address;
            const deployer2 = nonOperator.address;

            await service.connect(operator).updateTokenDeployer(tokenId, deployer1);
            expect(await testToken.deployer()).to.equal(deployer1);

            await service.connect(operator).updateTokenDeployer(tokenId, deployer2);
            expect(await testToken.deployer()).to.equal(deployer2);

            const salt2 = getRandomBytes32();
            const tokenId2 = await tokenFactory.linkedTokenId(wallet.address, salt2);

            const testToken2 = await ethers.getContractFactory('TestHyperliquidInterchainToken', wallet);
            const deployedToken2 = await testToken2.deploy('TestToken2', 'TEST2', 18, service.address, tokenId2);

            await tokenFactory.registerCustomToken(salt2, deployedToken2.address, 1, wallet.address);

            const newDeployer = otherWallet.address;

            await service.connect(operator).updateTokenDeployer(tokenId, newDeployer);
            await service.connect(operator).updateTokenDeployer(tokenId2, newDeployer);

            expect(await testToken.deployer()).to.equal(newDeployer);
            expect(await deployedToken2.deployer()).to.equal(newDeployer);
        });
    });
});
