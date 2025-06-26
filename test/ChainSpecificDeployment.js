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

        // For Hyperliquid chains, hyperliquidInterchainToken should be defined
        expect(deployment.hyperliquidInterchainToken).to.not.be.undefined;
        expect(deployment.interchainToken).to.be.undefined;
        expect(deployment.interchainTokenDeployer).to.not.be.undefined;

        const hyperliquidImplementation = await deployment.interchainTokenDeployer.implementationAddress();
        expect(hyperliquidImplementation).to.equal(deployment.hyperliquidInterchainToken.address);

        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.interchainTokenDeployer.deployedAddress(salt);

        await deployment.interchainTokenDeployer.deployInterchainToken(salt, tokenId, wallet.address, 'TestToken', 'TEST', 18);

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

        // For standard chains, interchainToken should be defined
        expect(deployment.interchainToken).to.not.be.undefined;
        expect(deployment.hyperliquidInterchainToken).to.be.undefined;
        expect(deployment.interchainTokenDeployer).to.not.be.undefined;

        const standardImplementation = await deployment.interchainTokenDeployer.implementationAddress();
        expect(standardImplementation).to.equal(deployment.interchainToken.address);

        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.interchainTokenDeployer.deployedAddress(salt);

        await deployment.interchainTokenDeployer.deployInterchainToken(salt, tokenId, wallet.address, 'TestToken', 'TEST', 18);

        const token = await ethers.getContractAt('InterchainToken', tokenAddress, wallet);

        // Check that the token doesn't have a deployer property (standard tokens don't have this)
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

        await hyperliquidDeployment.interchainTokenDeployer.deployInterchainToken(salt1, tokenId, wallet.address, 'TestToken', 'TEST', 18);
        await standardDeployment.interchainTokenDeployer.deployInterchainToken(salt2, tokenId, wallet.address, 'TestToken', 'TEST', 18);

        const hyperliquidTokenAddress = await hyperliquidDeployment.interchainTokenDeployer.deployedAddress(salt1);
        const standardTokenAddress = await standardDeployment.interchainTokenDeployer.deployedAddress(salt2);

        const provider = ethers.provider;
        const hyperliquidSlot0 = await provider.getStorageAt(hyperliquidTokenAddress, 0);
        const standardSlot0 = await provider.getStorageAt(standardTokenAddress, 0);

        expect(hyperliquidSlot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        expect(standardSlot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });
});
