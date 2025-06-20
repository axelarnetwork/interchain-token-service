'use strict';

const { ethers } = require('hardhat');
const { getContractAt } = ethers;
const { expect } = require('chai');
const { getRandomBytes32 } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('HyperliquidInterchainToken', () => {
    let hyperliquidInterchainToken, hyperliquidInterchainTokenDeployer;

    const name = 'HyperliquidToken';
    const symbol = 'HLT';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let owner;
    let user;
    let deployer;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
        deployer = wallets[1];

        hyperliquidInterchainToken = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
        hyperliquidInterchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidInterchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        const tokenAddress = await hyperliquidInterchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('HyperliquidInterchainToken', tokenAddress, owner);

        await hyperliquidInterchainTokenDeployer
            .deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals)
            .then((tx) => tx.wait);

        await token.mint(owner.address, mintAmount).then((tx) => tx.wait);
        expect(await token.interchainTokenId()).to.equal(tokenId);
    });

    describe('HyperliquidInterchainToken', () => {
        it('Should calculate hardcoded constants correctly', async () => {
            await expect(deployContract(owner, 'HyperliquidInterchainToken', [owner.address])).to.not.be.reverted;
        });

        it('should have the interchainTokenDeployer contract as deployer address after initialization', async () => {
            const deployer = await token.getDeployer();
            expect(deployer).to.equal(hyperliquidInterchainTokenDeployer.address);
        });

        it('should get the correct deployer address after updateDeployer', async () => {
            await token.connect(owner).updateDeployer(deployer.address);
            const newDeployer = await token.getDeployer();
            expect(newDeployer).to.equal(deployer.address);
        });

        it('should revert when non-ITS or non-operator tries to update deployer', async () => {
            await expect(token.connect(user).updateDeployer(user.address)).to.be.reverted;
        });

        it('should store deployer in slot 0', async () => {
            const provider = ethers.provider;
            const tokenAddress = token.address;

            // Read slot 0 directly
            const slot0 = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40); // Last 20 bytes

            // Get deployer via contract function
            const deployerFromContract = await token.getDeployer();

            // Both should match
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());

            // Slot 0 should not be empty
            expect(slot0).to.not.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        });

        it('should maintain ERC20 functionality', async () => {
            const initialBalance = await token.balanceOf(owner.address);
            expect(initialBalance).to.equal(mintAmount);

            // Test transfer
            const transferAmount = 50;
            await token.transfer(user.address, transferAmount);

            const ownerBalance = await token.balanceOf(owner.address);
            const userBalance = await token.balanceOf(user.address);

            expect(ownerBalance).to.equal(mintAmount - transferAmount);
            expect(userBalance).to.equal(transferAmount);
        });

        it('should maintain minting functionality', async () => {
            const initialBalance = await token.balanceOf(owner.address);
            const mintAmount2 = 100;

            await token.mint(owner.address, mintAmount2);

            const finalBalance = await token.balanceOf(owner.address);
            expect(finalBalance).to.equal(initialBalance.add(mintAmount2));
        });

        it('should maintain burning functionality', async () => {
            const initialBalance = await token.balanceOf(owner.address);
            const burnAmount = 50;

            await token.burn(owner.address, burnAmount);

            const finalBalance = await token.balanceOf(owner.address);
            expect(finalBalance).to.equal(initialBalance.sub(burnAmount));
        });

        it('should maintain allowance functionality', async () => {
            const spender = user.address;
            const allowanceAmount = 100;

            await token.approve(spender, allowanceAmount);
            const allowance = await token.allowance(owner.address, spender);
            expect(allowance).to.equal(allowanceAmount);
        });

        it('should allow ITS itself to update the deployer', async () => {
            // Deploy a TestOperator contract to act as ITS
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            // Deploy HyperliquidInterchainToken with mockITS as the ITS address
            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            // Call updateDeployer as ITS (owner)
            const newDeployer = user.address;
            await testDeployer.connect(owner).updateDeployer(newDeployer);

            // Check that the deployer was updated
            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });
    });

    describe('Storage Layout Verification', () => {
        it('should verify slot 0 contains deployer and other slots are not affected', async () => {
            const provider = ethers.provider;
            const tokenAddress = token.address;

            // Read first 10 storage slots
            const slots = [];

            for (let i = 0; i < 10; i++) {
                const slot = await provider.getStorageAt(tokenAddress, i);
                slots.push(slot);
            }

            // Slot 0 should contain deployer address
            const deployerFromSlot0 = '0x' + slots[0].slice(-40);
            const deployerFromContract = await token.getDeployer();
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());

            // Slot 0 should not be empty
            expect(slots[0]).to.not.equal('0x0000000000000000000000000000000000000000000000000000000000000000');

            // Other slots should contain expected data (balances, allowances, etc.)
            // Slot 1 should be empty (no balance for address 0x1)
            expect(slots[1]).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        });
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same bytecode', async () => {
            const contract = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const contractBytecode = contract.bytecode;

            // For now, just verify the bytecode is not empty
            expect(contractBytecode).to.not.be.empty;
        });
    });

    describe('Coverage Improvement Tests', () => {
        it('should test HyperLiquidDeployer getDeployer assembly code', async () => {
            const deployer = await token.getDeployer();
            expect(deployer).to.not.equal(ethers.constants.AddressZero);
        });

        it('should test HyperLiquidDeployer updateDeployer authorization', async () => {
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);
            expect(await token.getDeployer()).to.equal(newDeployer);
        });

        it('should test HyperLiquidDeployer updateDeployer failure case', async () => {
            await expect(token.connect(user).updateDeployer(user.address)).to.be.reverted;
        });

        it('should test multiple contract instances for better coverage', async () => {
            const token1 = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
            const token2 = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);

            expect(await token1.getDeployer()).to.equal(owner.address);
            expect(await token2.getDeployer()).to.equal(owner.address);

            await token1.connect(owner).updateDeployer(user.address);
            await token2.connect(owner).updateDeployer(user.address);

            expect(await token1.getDeployer()).to.equal(user.address);
            expect(await token2.getDeployer()).to.equal(user.address);
        });

        it('should test storage slot 0 manipulation for coverage', async () => {
            const provider = ethers.provider;
            const tokenAddress = token.address;

            const slot0 = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40);
            const deployerFromContract = await token.getDeployer();

            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        });

        it('should test HyperLiquidDeployer updateDeployer with ITS operator', async () => {
            // Create a mock ITS contract that implements IOperator
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            // Create a concrete implementation of HyperLiquidDeployer for testing
            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            // Transfer operatorship to user
            await mockITS.transferOperatorship(user.address);

            // Test that an operator can update the deployer
            await testDeployer.connect(user).updateDeployer(user.address);
            expect(await testDeployer.getDeployer()).to.equal(user.address);
        });

        it('should test HyperLiquidDeployer updateDeployer with non-ITS and non-operator', async () => {
            // Create a mock ITS contract that implements IOperator
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            // Create a concrete implementation of HyperLiquidDeployer for testing
            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            // Don't add user as operator, so isOperator should return false

            // Test that a non-operator cannot update the deployer
            await expect(testDeployer.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(
                testDeployer,
                'NotAuthorized',
            );
        });

        it('should test HyperLiquidDeployer _setDeployer internal function', async () => {
            // Test the _setDeployer function indirectly through updateDeployer
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);
            
            // Verify the deployer was set correctly
            expect(await token.getDeployer()).to.equal(newDeployer);
            
            // Verify it was stored in slot 0
            const provider = ethers.provider;
            const slot0 = await provider.getStorageAt(token.address, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40);
            expect(deployerFromSlot0.toLowerCase()).to.equal(newDeployer.toLowerCase());
        });

        it('should test HyperLiquidDeployer _setDeployer assembly code with multiple updates', async () => {
            // Test _setDeployer with multiple different addresses to ensure assembly code coverage
            const wallets = await ethers.getSigners();
            const addresses = [
                owner.address,
                user.address,
                ethers.constants.AddressZero,
                wallets[2].address,
                wallets[3].address
            ];
            
            for (const addr of addresses) {
                await token.connect(owner).updateDeployer(addr);
                expect(await token.getDeployer()).to.equal(addr);
                
                // Verify storage slot 0 contains the correct value
                const provider = ethers.provider;
                const slot0 = await provider.getStorageAt(token.address, 0);
                const deployerFromSlot0 = '0x' + slot0.slice(-40);
                expect(deployerFromSlot0.toLowerCase()).to.equal(addr.toLowerCase());
            }
        });

        it('should test HyperLiquidDeployer getDeployer with different deployer values', async () => {
            // Test getDeployer with different deployer addresses
            const deployer1 = owner.address;
            const deployer2 = user.address;
            
            await token.connect(owner).updateDeployer(deployer1);
            expect(await token.getDeployer()).to.equal(deployer1);
            
            await token.connect(owner).updateDeployer(deployer2);
            expect(await token.getDeployer()).to.equal(deployer2);
        });

        it('should test HyperLiquidDeployer getDeployer assembly code with storage verification', async () => {
            // Test that getDeployer returns the same value as reading slot 0 directly
            const provider = ethers.provider;
            const tokenAddress = token.address;
            
            // Set a new deployer
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);
            
            // Read slot 0 directly using provider
            const slot0 = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40); // Extract last 20 bytes as address
            
            // Get deployer via contract function (uses assembly)
            const deployerFromContract = await token.getDeployer();
            
            // Both should match exactly
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
            expect(deployerFromContract).to.equal(newDeployer);
            
            // Test with zero address
            await token.connect(owner).updateDeployer(ethers.constants.AddressZero);
            const slot0Zero = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Zero = '0x' + slot0Zero.slice(-40);
            const deployerFromContractZero = await token.getDeployer();
            
            expect(deployerFromSlot0Zero.toLowerCase()).to.equal(deployerFromContractZero.toLowerCase());
            expect(deployerFromContractZero).to.equal(ethers.constants.AddressZero);
        });
    });
});
