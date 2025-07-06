'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const { getRandomBytes32 } = require('./utils');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

describe('HyperliquidInterchainTokenService', () => {
    let wallet, otherWallet, operator;
    let service, tokenFactory;
    let testToken, tokenId;

    before(async () => {
        [wallet, otherWallet, operator] = await ethers.getSigners();

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
            const currentOwner = await service.owner();

            if (currentOwner !== wallet.address) {
                await service.connect(ethers.provider.getSigner(currentOwner)).transferOwnership(wallet.address);
            }

            const salt = getRandomBytes32();
            await tokenFactory.deployInterchainToken(salt, 'TestToken', 'TEST', 18, 1000000, wallet.address).then((tx) => tx.wait());
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.registeredTokenAddress(tokenId);
            testToken = await ethers.getContractAt('HyperliquidInterchainToken', tokenAddress);
        });

        it('should revert if token manager does not exist', async () => {
            const nonExistentTokenId = getRandomBytes32();
            const newDeployer = otherWallet.address;
            await expect(service.connect(operator).updateTokenDeployer(nonExistentTokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'TokenManagerDoesNotExist',
            );
        });

        it('should update deployer from owner to a new owner and back to original owner', async () => {
            const newDeployer = otherWallet.address;

            expect(await testToken.deployer()).to.equal(ethers.constants.AddressZero);

            await expect(service.connect(operator).updateTokenDeployer(tokenId, wallet.address))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, wallet.address, operator.address);
            expect(await testToken.deployer()).to.equal(wallet.address);

            await service.connect(wallet).transferOwnership(otherWallet.address);
            expect(await service.owner()).to.equal(otherWallet.address);

            await expect(service.connect(otherWallet).updateTokenDeployer(tokenId, newDeployer))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, newDeployer, otherWallet.address);
            expect(await testToken.deployer()).to.equal(newDeployer);

            await service.connect(otherWallet).transferOwnership(wallet.address);
            expect(await service.owner()).to.equal(wallet.address);

            await expect(service.connect(wallet).updateTokenDeployer(tokenId, wallet.address))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, wallet.address, wallet.address);
            expect(await testToken.deployer()).to.equal(wallet.address);
        });

        it('should revert once owner is not operator and cannot update deployer', async () => {
            const newDeployer = otherWallet.address;

            expect(await testToken.deployer()).to.equal(ethers.constants.AddressZero);

            await expect(service.connect(operator).updateTokenDeployer(tokenId, wallet.address))
                .to.emit(service, 'TokenDeployerUpdated')
                .withArgs(testToken.address, wallet.address, operator.address);
            expect(await testToken.deployer()).to.equal(wallet.address);

            await service.connect(wallet).transferOwnership(otherWallet.address);
            expect(await service.owner()).to.equal(otherWallet.address);

            await expect(service.connect(wallet).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should revert when called by non-owner and non-operator wallet', async () => {
            const newDeployer = otherWallet.address;
            await expect(service.connect(otherWallet).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });
    });
});
