'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('HyperLiquidDeployer', () => {
    let TestHyperLiquidDeployer, testDeployer;
    let owner, user, operator;
    let MockITS, mockITS;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
        operator = wallets[2];

        // Deploy mock ITS contract
        MockITS = await ethers.getContractFactory('TestTokenManager');
        mockITS = await MockITS.deploy(owner.address);

        // Deploy test implementation
        TestHyperLiquidDeployer = await ethers.getContractFactory('TestHyperliquidDeployer');
        testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address, owner.address);
    });

    describe('Constructor and Initial State', () => {
        it('Should set initial deployer correctly', async () => {
            expect(await testDeployer.getDeployer()).to.equal(owner.address);
            expect(await testDeployer.initialDeployer()).to.equal(owner.address);
        });

        it('Should set ITS address correctly', async () => {
            expect(await testDeployer.itsAddress()).to.equal(mockITS.address);
        });
    });

    describe('getDeployer() - Line 25 Assembly Coverage', () => {
        it('Should read deployer from slot 0 using assembly', async () => {
            // This test specifically targets line 25 (assembly sload)
            const deployer = await testDeployer.getDeployer();
            expect(deployer).to.equal(owner.address);

            // Verify the assembly code works by reading storage directly
            const provider = ethers.provider;
            const slot0 = await provider.getStorageAt(testDeployer.address, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40);
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployer.toLowerCase());
        });

        it('Should handle zero address in slot 0', async () => {
            // Set deployer to zero address
            await testDeployer.testSetDeployer(ethers.constants.AddressZero);

            const deployer = await testDeployer.getDeployer();
            expect(deployer).to.equal(ethers.constants.AddressZero);
        });

        it('Should handle various addresses in slot 0', async () => {
            const testAddresses = [
                user.address,
                operator.address,
                '0x1111111111111111111111111111111111111111',
                '0x2222222222222222222222222222222222222222',
            ];

            for (const addr of testAddresses) {
                await testDeployer.testSetDeployer(addr);
                const deployer = await testDeployer.getDeployer();
                expect(deployer).to.equal(addr);
            }
        });
    });

    describe('_setDeployer() - Assembly Coverage', () => {
        it('Should write to slot 0 using assembly', async () => {
            const newDeployer = user.address;
            await testDeployer.testSetDeployer(newDeployer);

            expect(await testDeployer.getDeployer()).to.equal(newDeployer);

            // Verify storage slot directly
            const provider = ethers.provider;
            const slot0 = await provider.getStorageAt(testDeployer.address, 0);
            const deployerFromSlot0 = '0x' + slot0.slice(-40);
            expect(deployerFromSlot0.toLowerCase()).to.equal(newDeployer.toLowerCase());
        });

        it('Should handle multiple rapid updates', async () => {
            const addresses = [
                user.address,
                operator.address,
                ethers.constants.AddressZero,
                '0x1111111111111111111111111111111111111111',
                '0x2222222222222222222222222222222222222222',
            ];

            for (const addr of addresses) {
                await testDeployer.testSetDeployer(addr);
                expect(await testDeployer.getDeployer()).to.equal(addr);
            }
        });
    });

    describe('updateDeployer() - Lines 46-47 Authorization Coverage', () => {
        beforeEach(async () => {
            // Set operator as the current deployer so they can call updateDeployer
            await testDeployer.testSetDeployer(operator.address);
        });

        it('Should allow ITS to update deployer', async () => {
            // Impersonate ITS contract and fund it
            await ethers.provider.send('hardhat_impersonateAccount', [mockITS.address]);
            await ethers.provider.send('hardhat_setBalance', [mockITS.address, '0x1000000000000000000']); // 1 ETH
            const itsSigner = await ethers.getSigner(mockITS.address);

            const newDeployer = user.address;
            await testDeployer.connect(itsSigner).updateDeployer(newDeployer);

            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });

        it('Should allow current deployer (operator) to update deployer', async () => {
            const newDeployer = user.address;
            await testDeployer.connect(operator).updateDeployer(newDeployer);

            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });

        it('Should allow initial deployer to update deployer', async () => {
            const newDeployer = user.address;
            await testDeployer.connect(owner).updateDeployer(newDeployer);

            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });

        it('Should revert when unauthorized caller tries to update', async () => {
            const newDeployer = user.address;

            await expect(testDeployer.connect(user).updateDeployer(newDeployer)).to.be.revertedWithCustomError(
                testDeployer,
                'NotAuthorized',
            );
        });

        it('Should revert when non-authorized tries to update', async () => {
            // Set a different deployer so operator is no longer authorized
            await testDeployer.testSetDeployer(user.address);

            const newDeployer = operator.address;
            await expect(testDeployer.connect(operator).updateDeployer(newDeployer)).to.be.revertedWithCustomError(
                testDeployer,
                'NotAuthorized',
            );
        });
    });

    describe('_getInterchainTokenService() - Line 52 Coverage', () => {
        it('Should return correct ITS address', async () => {
            // This test indirectly covers line 52 by calling updateDeployer
            // which internally calls _getInterchainTokenService()

            // Set operator as current deployer
            await testDeployer.testSetDeployer(operator.address);

            const newDeployer = user.address;
            await testDeployer.connect(operator).updateDeployer(newDeployer);

            // Verify the function worked (which means _getInterchainTokenService was called)
            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });

        it('Should work with different ITS addresses', async () => {
            // Create a new mock ITS for this test
            const newMockITS = await MockITS.deploy(owner.address);

            // Update the test deployer to use the new ITS
            await testDeployer.setITSAddress(newMockITS.address);

            // Set operator as current deployer
            await testDeployer.testSetDeployer(operator.address);

            const newDeployer = user.address;
            await testDeployer.connect(operator).updateDeployer(newDeployer);

            expect(await testDeployer.getDeployer()).to.equal(newDeployer);
        });
    });

    describe('Edge Cases and Error Handling', () => {
        it('Should handle zero address as new deployer', async () => {
            await testDeployer.testSetDeployer(operator.address);

            await testDeployer.connect(operator).updateDeployer(ethers.constants.AddressZero);
            expect(await testDeployer.getDeployer()).to.equal(ethers.constants.AddressZero);
        });

        it('Should handle contract addresses as deployer', async () => {
            await testDeployer.testSetDeployer(operator.address);

            await testDeployer.connect(operator).updateDeployer(mockITS.address);
            expect(await testDeployer.getDeployer()).to.equal(mockITS.address);
        });

        it('Should maintain deployer across multiple updates', async () => {
            await testDeployer.testSetDeployer(operator.address);

            const addresses = [user.address, owner.address, mockITS.address];

            for (const addr of addresses) {
                await testDeployer.connect(operator).updateDeployer(addr);
                expect(await testDeployer.getDeployer()).to.equal(addr);

                // Set operator back as deployer for the next iteration
                await testDeployer.testSetDeployer(operator.address);
            }
        });
    });
});
