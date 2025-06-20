'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');
const { deployAll } = require('../scripts/deploy');

describe('Chain-Specific Token Deployment', () => {
    let wallet;

    before(async () => {
        [wallet] = await ethers.getSigners();
    });

    it('should deploy HyperliquidInterchainToken for Hyperliquid chain', async () => {
        console.log('\n=== Testing Hyperliquid Chain Deployment ===');
        
        const deployment = await deployAll(
            wallet,
            'hyperliquid',
            [],
            'HyperliquidInterchainTokenService',
            'HyperliquidInterchainTokenServiceFactory',
        );

        console.log('Deployed contracts:');
        console.log('- InterchainTokenService:', deployment.service.address);
        console.log('- Standard InterchainToken:', deployment.interchainToken.address);
        console.log('- HyperliquidInterchainToken:', deployment.hyperliquidInterchainToken.address);
        console.log('- Standard InterchainTokenDeployer:', deployment.interchainTokenDeployer.address);
        console.log('- HyperliquidInterchainTokenDeployer:', deployment.hyperliquidInterchainTokenDeployer.address);
        console.log('- Active Token Deployer:', deployment.activeTokenDeployer.address);

        // Verify that the active deployer is the Hyperliquid one
        expect(deployment.activeTokenDeployer.address).to.equal(deployment.hyperliquidInterchainTokenDeployer.address);
        
        // Verify that the Hyperliquid deployer points to HyperliquidInterchainToken
        const hyperliquidImplementation = await deployment.hyperliquidInterchainTokenDeployer.implementationAddress();
        expect(hyperliquidImplementation).to.equal(deployment.hyperliquidInterchainToken.address);

        // Test deploying a new token using the Hyperliquid deployer
        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.activeTokenDeployer.deployedAddress(salt);
        
        await deployment.activeTokenDeployer.deployInterchainToken(
            salt,
            tokenId,
            wallet.address,
            'TestToken',
            'TEST',
            18,
        );

        // Verify the deployed token has Hyperliquid functionality
        const token = await ethers.getContractAt('HyperliquidInterchainToken', tokenAddress, wallet);
        const deployer = await token.getDeployer();
        expect(deployer).to.equal(deployment.activeTokenDeployer.address);

        console.log('✅ Hyperliquid deployment successful!');
        console.log('- Deployed token address:', tokenAddress);
        console.log('- Token deployer:', deployer);
    });

    it('should deploy standard InterchainToken for other chains', async () => {
        console.log('\n=== Testing Standard Chain Deployment ===');
        
        const deployment = await deployAll(
            wallet,
            'avalanche', // Standard chain
            [],
            'StandardInterchainTokenService',
            'StandardInterchainTokenServiceFactory',
        );

        console.log('Deployed contracts:');
        console.log('- InterchainTokenService:', deployment.service.address);
        console.log('- Standard InterchainToken:', deployment.interchainToken.address);
        console.log('- HyperliquidInterchainToken:', deployment.hyperliquidInterchainToken.address);
        console.log('- Standard InterchainTokenDeployer:', deployment.interchainTokenDeployer.address);
        console.log('- HyperliquidInterchainTokenDeployer:', deployment.hyperliquidInterchainTokenDeployer.address);
        console.log('- Active Token Deployer:', deployment.activeTokenDeployer.address);

        // Verify that the active deployer is the standard one
        expect(deployment.activeTokenDeployer.address).to.equal(deployment.interchainTokenDeployer.address);
        
        // Verify that the standard deployer points to InterchainToken
        const standardImplementation = await deployment.interchainTokenDeployer.implementationAddress();
        expect(standardImplementation).to.equal(deployment.interchainToken.address);

        // Test deploying a new token using the standard deployer
        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);
        const tokenAddress = await deployment.activeTokenDeployer.deployedAddress(salt);
        
        await deployment.activeTokenDeployer.deployInterchainToken(
            salt,
            tokenId,
            wallet.address,
            'TestToken',
            'TEST',
            18,
        );

        // Verify the deployed token is a standard InterchainToken (no getDeployer function)
        const token = await ethers.getContractAt('InterchainToken', tokenAddress, wallet);
        
        // Standard InterchainToken should not have getDeployer function
        expect(token.getDeployer).to.be.undefined;

        console.log('✅ Standard deployment successful!');
        console.log('- Deployed token address:', tokenAddress);
        console.log('- Token type: Standard InterchainToken (no deployer function)');
    });

    it('should verify storage layout differences', async () => {
        console.log('\n=== Testing Storage Layout Differences ===');
        
        // Deploy both types
        const hyperliquidDeployment = await deployAll(wallet, 'hyperliquid', [], 'HyperliquidTest', 'HyperliquidTestFactory');
        const standardDeployment = await deployAll(wallet, 'avalanche', [], 'StandardTest', 'StandardTestFactory');

        // Deploy tokens using each deployer
        const salt1 = ethers.utils.randomBytes(32);
        const salt2 = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);

        await hyperliquidDeployment.activeTokenDeployer.deployInterchainToken(
            salt1, tokenId, wallet.address, 'TestToken', 'TEST', 18,
        );
        await standardDeployment.activeTokenDeployer.deployInterchainToken(
            salt2, tokenId, wallet.address, 'TestToken', 'TEST', 18,
        );

        const hyperliquidTokenAddress = await hyperliquidDeployment.activeTokenDeployer.deployedAddress(salt1);
        const standardTokenAddress = await standardDeployment.activeTokenDeployer.deployedAddress(salt2);

        // Check slot 0 for both tokens
        const provider = ethers.provider;
        const hyperliquidSlot0 = await provider.getStorageAt(hyperliquidTokenAddress, 0);
        const standardSlot0 = await provider.getStorageAt(standardTokenAddress, 0);

        console.log('Storage slot 0 comparison:');
        console.log('- Hyperliquid token slot 0:', hyperliquidSlot0);
        console.log('- Standard token slot 0:', standardSlot0);

        // Hyperliquid should have deployer in slot 0, standard should be empty
        expect(hyperliquidSlot0).to.not.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        expect(standardSlot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');

        console.log('✅ Storage layout verification successful!');
        console.log('- Hyperliquid: Slot 0 contains deployer (reserved)');
        console.log('- Standard: Slot 0 is empty (available for ERC20 balances)');
    });
}); 