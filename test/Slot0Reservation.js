'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');
const { deployContract } = require('../scripts/deploy');

describe('Slot 0 Reservation', () => {
    let hyperliquidToken;
    let owner;
    let user;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];

        // Deploy the HyperliquidInterchainToken implementation
        hyperliquidToken = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
    });

    it('should have deployerSlot0 state variable in slot 0', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        // Read slot 0 directly
        const slot0 = await provider.getStorageAt(tokenAddress, 0);

        // Slot 0 should be empty (address(0)) initially
        const deployerFromSlot0 = '0x' + slot0.slice(-40); // Last 20 bytes
        expect(deployerFromSlot0.toLowerCase()).to.equal(ethers.constants.AddressZero.toLowerCase());
        expect(slot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });

    it('should get deployer via contract function', async () => {
        const deployer = await hyperliquidToken.getDeployer();
        expect(deployer.toLowerCase()).to.equal(ethers.constants.AddressZero.toLowerCase());
    });

    it('should verify slot 0 and contract function return same value', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        // Read slot 0 directly
        const slot0 = await provider.getStorageAt(tokenAddress, 0);
        const deployerFromSlot0 = '0x' + slot0.slice(-40);

        // Get deployer via contract function
        const deployerFromContract = await hyperliquidToken.getDeployer();

        // Both should match and be address(0)
        expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        expect(deployerFromContract.toLowerCase()).to.equal(ethers.constants.AddressZero.toLowerCase());
    });

    it('should update deployer and verify slot 0 changes', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        // Read initial slot 0
        const initialSlot0 = await provider.getStorageAt(tokenAddress, 0);

        // Check current deployer and service state
        const currentDeployer = await hyperliquidToken.getDeployer();
        const serviceAddress = await hyperliquidToken.interchainTokenService();

        console.log('Slot0Reservation - Current deployer:', currentDeployer);
        console.log('Slot0Reservation - Service address:', serviceAddress);

        // Try to update deployer based on current authorization state
        if (currentDeployer !== ethers.constants.AddressZero) {
            // Use the current deployer to update
            const deployerSigner = await ethers.getSigner(currentDeployer);
            await hyperliquidToken.connect(deployerSigner).updateDeployer(user.address);
        } else if (serviceAddress !== ethers.constants.AddressZero) {
            // If no deployer but service is set, use service
            const serviceSigner = await ethers.getSigner(serviceAddress);
            await hyperliquidToken.connect(serviceSigner).updateDeployer(user.address);
        } else {
            // If neither is set, test that unauthorized calls revert
            await expect(hyperliquidToken.connect(user).updateDeployer(user.address)).to.be.revertedWith('NotAuthorized');

            // Verify the deployer is still zero
            expect(await hyperliquidToken.getDeployer()).to.equal(ethers.constants.AddressZero);
            return; // Exit early since we can't update
        }

        // Read updated slot 0
        const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
        const updatedDeployer = await hyperliquidToken.getDeployer();

        // Verify changes
        expect(updatedDeployer).to.equal(user.address);
        expect(updatedSlot0).to.not.equal(initialSlot0);

        // Verify slot 0 contains the new deployer
        const deployerFromSlot0 = '0x' + updatedSlot0.slice(-40);
        expect(deployerFromSlot0.toLowerCase()).to.equal(user.address.toLowerCase());
    });

    it('should verify slot 0 is reserved and not overwritten by other variables', async () => {
        const provider = ethers.provider;

        // Deploy a new token instance to test initialization
        const hyperliquidTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidToken.address]);
        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);

        const newTokenAddress = await hyperliquidTokenDeployer.deployedAddress(salt);
        const newToken = await ethers.getContractAt('HyperliquidInterchainToken', newTokenAddress, owner);

        // Initialize the token (this should not set deployer)
        await hyperliquidTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18);

        // Read slot 0 after initialization
        const slot0 = await provider.getStorageAt(newTokenAddress, 0);
        const deployerFromSlot0 = '0x' + slot0.slice(-40);
        const deployerFromContract = await newToken.getDeployer();

        // Slot 0 should be empty (address(0))
        expect(deployerFromSlot0.toLowerCase()).to.equal(ethers.constants.AddressZero.toLowerCase());
        expect(deployerFromContract.toLowerCase()).to.equal(ethers.constants.AddressZero.toLowerCase());

        // Verify the token name is set correctly (should be in a different slot)
        const tokenName = await newToken.name();
        expect(tokenName).to.equal('TestToken');

        // Verify slot 0 still contains address(0), not the name
        const slot0AfterName = await provider.getStorageAt(newTokenAddress, 0);
        expect(slot0AfterName).to.equal(slot0); // Should not have changed
    });
});
