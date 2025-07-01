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
            const tx = await tokenFactory.deployInterchainToken(
                salt,
                'TestToken',
                'TEST',
                18,
                1000000,
                wallet.address
            );
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.registeredTokenAddress(tokenId);
            testToken = await ethers.getContractAt('HyperliquidInterchainToken', tokenAddress);
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
            const customTokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
            const TestToken = await ethers.getContractFactory('TestInterchainTokenStandard', wallet);
            const simpleToken = await TestToken.deploy('SimpleToken', 'SIMPLE', 18, service.address, customTokenId);
            await tokenFactory.registerCustomToken(salt, simpleToken.address, 1, wallet.address);
            const newDeployer = otherWallet.address;
            await expect(service.connect(operator).updateTokenDeployer(customTokenId, newDeployer))
                .to.be.revertedWithCustomError(service, 'TokenDoesNotSupportHyperliquidInterface')
                .withArgs(simpleToken.address);
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

        it('should update deployer from owner to a new owner and back to original owner', async () => {
            const newDeployer = otherWallet.address;

            expect(await testToken.deployer()).to.equal(ethers.constants.AddressZero);

            await expect(service.connect(operator).updateTokenDeployer(tokenId, wallet.address))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, wallet.address, operator.address);
            expect(await testToken.deployer()).to.equal(wallet.address);

            await expect(service.connect(operator).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, operator.address);
            expect(await testToken.deployer()).to.equal(newDeployer);

            await expect(service.connect(wallet).updateTokenDeployer(tokenId, wallet.address))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, wallet.address, wallet.address);
            expect(await testToken.deployer()).to.equal(wallet.address);
        });
    });
});
