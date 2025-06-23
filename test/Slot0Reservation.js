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

        // Slot 0 should contain the deployer address (msg.sender from constructor)
        const deployerFromSlot0 = '0x' + slot0.slice(-40); // Last 20 bytes
        expect(deployerFromSlot0.toLowerCase()).to.equal(owner.address.toLowerCase());

        // Slot 0 should not be empty
        expect(slot0).to.not.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });

    it('should get deployer via contract function', async () => {
        const deployer = await hyperliquidToken.getDeployer();
        expect(deployer.toLowerCase()).to.equal(owner.address.toLowerCase());
    });

    it('should verify slot 0 and contract function return same value', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        // Read slot 0 directly
        const slot0 = await provider.getStorageAt(tokenAddress, 0);
        const deployerFromSlot0 = '0x' + slot0.slice(-40);

        // Get deployer via contract function
        const deployerFromContract = await hyperliquidToken.getDeployer();

        // Both should match
        expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
    });

    it('should update deployer and verify slot 0 changes', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        // Read initial slot 0
        const initialSlot0 = await provider.getStorageAt(tokenAddress, 0);

        // Update deployer (only owner can do this as they are the ITS)
        await hyperliquidToken.connect(owner).updateDeployer(user.address);

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

    it('should show storage layout for first 5 slots', async () => {
        const provider = ethers.provider;
        const tokenAddress = hyperliquidToken.address;

        console.log('\nStorage Layout for HyperliquidInterchainToken:');

        for (let i = 0; i < 5; i++) {
            const slot = await provider.getStorageAt(tokenAddress, i);
            const isEmpty = slot === '0x0000000000000000000000000000000000000000000000000000000000000000';
            const asAddress = '0x' + slot.slice(-40);

            console.log(`Slot ${i}: ${slot} ${isEmpty ? '(empty)' : ''}`);

            if (!isEmpty) {
                console.log(`  As address: ${asAddress}`);
                console.log(`  As number: ${parseInt(slot, 16)}`);
            }
        }

        // Slot 0 should contain deployer address
        const slot0 = await provider.getStorageAt(tokenAddress, 0);
        const deployerFromSlot0 = '0x' + slot0.slice(-40);
        const deployerFromContract = await hyperliquidToken.getDeployer();

        expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
    });

    it('should verify slot 0 is reserved and not overwritten by other variables', async () => {
        const provider = ethers.provider;

        // Deploy a new token instance to test initialization
        const hyperliquidTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidToken.address]);
        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);

        const newTokenAddress = await hyperliquidTokenDeployer.deployedAddress(salt);
        const newToken = await ethers.getContractAt('HyperliquidInterchainToken', newTokenAddress, owner);

        // Initialize the token (this should set deployer first, then other variables)
        await hyperliquidTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18);

        // Read slot 0 after initialization
        const slot0 = await provider.getStorageAt(newTokenAddress, 0);
        const deployerFromSlot0 = '0x' + slot0.slice(-40);
        const deployerFromContract = await newToken.getDeployer();

        // Slot 0 should contain the deployer address
        expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        expect(deployerFromContract.toLowerCase()).to.equal(hyperliquidTokenDeployer.address.toLowerCase());

        // Verify the token name is set correctly (should be in a different slot)
        const tokenName = await newToken.name();
        expect(tokenName).to.equal('TestToken');

        // Verify slot 0 still contains deployer, not the name
        const slot0AfterName = await provider.getStorageAt(newTokenAddress, 0);
        expect(slot0AfterName).to.equal(slot0); // Should not have changed

        console.log('\nVerification:');
        console.log(`Slot 0: ${slot0}`);
        console.log(`Deployer from slot 0: ${deployerFromSlot0}`);
        console.log(`Deployer from contract: ${deployerFromContract}`);
        console.log(`Token name: ${tokenName}`);
        console.log(`Slot 0 unchanged: ${slot0AfterName === slot0}`);
    });
});
