'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

describe('Chain-Specific Token Deployment', () => {
    let wallet;

    before(async () => {
        [wallet] = await ethers.getSigners();
    });

    it('should deploy HyperliquidInterchainToken for Hyperliquid chain', async () => {
        const deployment = await deployAll(
            wallet,
            'hyperliquid',
            ITS_HUB_ADDRESS,
            [],
            'HyperliquidInterchainTokenService',
            'HyperliquidInterchainTokenServiceFactory',
        );

        expect(deployment.activeTokenDeployer.address).to.equal(deployment.hyperliquidInterchainTokenDeployer.address);

        const hyperliquidImplementation = await deployment.hyperliquidInterchainTokenDeployer.implementationAddress();
        expect(hyperliquidImplementation).to.equal(deployment.hyperliquidInterchainToken.address);

        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.activeTokenDeployer.deployedAddress(salt);

        await deployment.activeTokenDeployer.deployInterchainToken(salt, tokenId, wallet.address, 'TestToken', 'TEST', 18);

        const token = await ethers.getContractAt('HyperliquidInterchainToken', tokenAddress, wallet);
        const deployer = await token.deployer();
        expect(deployer).to.equal(ethers.constants.AddressZero);
    });

    it('should deploy standard InterchainToken for other chains', async () => {
        const deployment = await deployAll(
            wallet,
            'avalanche',
            ITS_HUB_ADDRESS,
            [],
            'StandardInterchainTokenService',
            'StandardInterchainTokenServiceFactory',
        );

        expect(deployment.activeTokenDeployer.address).to.equal(deployment.interchainTokenDeployer.address);

        const standardImplementation = await deployment.interchainTokenDeployer.implementationAddress();
        expect(standardImplementation).to.equal(deployment.interchainToken.address);

        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.activeTokenDeployer.deployedAddress(salt);

        await deployment.activeTokenDeployer.deployInterchainToken(salt, tokenId, wallet.address, 'TestToken', 'TEST', 18);

        const token = await ethers.getContractAt('InterchainToken', tokenAddress, wallet);

        expect(token.deployer).to.be.undefined;
    });

    it('should verify storage layout differences', async () => {
        const hyperliquidDeployment = await deployAll(
            wallet,
            'hyperliquid',
            ITS_HUB_ADDRESS,
            [],
            'HyperliquidTest',
            'HyperliquidTestFactory',
        );
        const standardDeployment = await deployAll(wallet, 'avalanche', ITS_HUB_ADDRESS, [], 'StandardTest', 'StandardTestFactory');

        const salt1 = ethers.utils.randomBytes(32);
        const salt2 = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);

        await hyperliquidDeployment.activeTokenDeployer.deployInterchainToken(salt1, tokenId, wallet.address, 'TestToken', 'TEST', 18);
        await standardDeployment.activeTokenDeployer.deployInterchainToken(salt2, tokenId, wallet.address, 'TestToken', 'TEST', 18);

        const hyperliquidTokenAddress = await hyperliquidDeployment.activeTokenDeployer.deployedAddress(salt1);
        const standardTokenAddress = await standardDeployment.activeTokenDeployer.deployedAddress(salt2);

        const provider = ethers.provider;
        const hyperliquidSlot0 = await provider.getStorageAt(hyperliquidTokenAddress, 0);
        const standardSlot0 = await provider.getStorageAt(standardTokenAddress, 0);

        expect(hyperliquidSlot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        expect(standardSlot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });
});
