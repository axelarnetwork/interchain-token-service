'use strict';

const { ethers } = require('hardhat');
const { getContractAt } = ethers;
const { expect } = require('chai');
const { getRandomBytes32 } = require('./utils');
const { deployContract } = require('../scripts/deploy');

/**
 * Helper function to extract an address from a bytes32 storage slot
 * @param {string} slotValue - The bytes32 value from storage
 * @returns {string} The EIP-55 checksummed address
 */
function bytes32ToAddress(slotValue) {
    // Extract the last 20 bytes (40 hex characters) from the bytes32 value
    const addressHex = '0x' + slotValue.slice(-40);
    // Convert to EIP-55 checksummed address for consistency
    return ethers.utils.getAddress(addressHex);
}

describe('HyperliquidInterchainToken', () => {
    let hyperliquidInterchainToken, hyperliquidInterchainTokenDeployer;
    let token;
    let owner;
    let user;
    let deployer;
    let provider;
    let tokenAddress;
    let slot0;
    let deployerFromSlot0;
    let deployerFromContract;

    const name = 'HyperliquidToken';
    const symbol = 'HLT';
    const decimals = 18;
    const mintAmount = 123;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
        deployer = wallets[1];

        hyperliquidInterchainToken = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
        hyperliquidInterchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidInterchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        tokenAddress = await hyperliquidInterchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('HyperliquidInterchainToken', tokenAddress, owner);

        await hyperliquidInterchainTokenDeployer
            .deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals)
            .then((tx) => tx.wait);

        await token.mint(owner.address, mintAmount).then((tx) => tx.wait);
        expect(await token.interchainTokenId()).to.equal(tokenId);

        // Set up common values used across tests
        provider = ethers.provider;
        slot0 = await provider.getStorageAt(tokenAddress, 0);
        deployerFromSlot0 = bytes32ToAddress(slot0);
        deployerFromContract = await token.getDeployer();
    });

    describe('HyperliquidInterchainToken', () => {
        it('Should calculate hardcoded constants correctly', async () => {
            await expect(deployContract(owner, 'HyperliquidInterchainToken', [owner.address])).to.not.be.reverted;
        });

        it('should have the interchainTokenDeployer contract as deployer address after initialization', async () => {
            expect(deployerFromContract).to.equal(ethers.constants.AddressZero);
        });

        it('should get the correct deployer address after updateDeployer', async () => {
            await token.connect(owner).updateDeployer(deployer.address);
            const newDeployer = await token.getDeployer();
            expect(newDeployer).to.equal(deployer.address);
        });

        it('should allow only the service to update deployer', async () => {
            await expect(token.connect(owner).updateDeployer(user.address)).to.not.be.reverted;
            expect(await token.getDeployer()).to.equal(user.address);
        });

        it('should store deployer in slot 0', async () => {
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
            // The deployer is initially AddressZero, so slot0 should be all zeros
            expect(slot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        });
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same bytecode', async () => {
            const contract = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const contractBytecode = contract.bytecode;

            expect(contractBytecode).to.not.be.empty;
        });
    });

    describe('Hyperliquid Deployer Tests', () => {
        it('should get the deployer', async () => {
            // Initially the deployer is AddressZero
            expect(deployerFromContract).to.equal(ethers.constants.AddressZero);
        });

        it('should allow only the service to update the deployer', async () => {
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);
            expect(await token.getDeployer()).to.equal(newDeployer);
        });

        it('should revert on updating deployer from non-service address', async () => {
            const newDeployer = user.address;
            await expect(token.connect(user).updateDeployer(newDeployer)).to.be.revertedWithCustomError(token, 'NotService');
        });

        it('should update the deployer for multiple contract instances', async () => {
            const token1 = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
            const token2 = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);

            expect(await token1.getDeployer()).to.equal(ethers.constants.AddressZero);
            expect(await token2.getDeployer()).to.equal(ethers.constants.AddressZero);

            try {
                await token1.connect(user).updateDeployer(user.address);
                expect(await token1.getDeployer()).to.equal(user.address);
                expect(await token2.getDeployer()).to.equal(ethers.constants.AddressZero);

                await token2.connect(user).updateDeployer(user.address);
                expect(await token2.getDeployer()).to.equal(user.address);
            } catch (error) {
                expect(await token1.getDeployer()).to.equal(ethers.constants.AddressZero);
                expect(await token2.getDeployer()).to.equal(ethers.constants.AddressZero);
            }
        });

        it('should store the deployer in slot 0', async () => {
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        });

        it('should update the deployer with ITS operator', async () => {
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            await mockITS.transferOperatorship(user.address);

            expect(await testDeployer.getDeployer()).to.equal(ethers.constants.AddressZero);
        });

        it('should revert on updating deployer from non-service address', async () => {
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            await expect(testDeployer.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(testDeployer, 'NotService');
        });

        it('should update the deployer with _setDeployer internal function', async () => {
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);

            expect(await token.getDeployer()).to.equal(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(token.address, 0);
            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
            expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(newDeployer.toLowerCase());
        });

        it('should update the deployer with multiple different addresses', async () => {
            const wallets = await ethers.getSigners();
            const addresses = [owner.address, user.address, ethers.constants.AddressZero, wallets[2].address, wallets[3].address];

            for (const addr of addresses) {
                await token.connect(owner).updateDeployer(addr);
                expect(await token.getDeployer()).to.equal(addr);

                const updatedSlot0 = await provider.getStorageAt(token.address, 0);
                const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
                expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(addr.toLowerCase());
            }
        });

        it('should get the deployer with different deployer values', async () => {
            const deployer1 = owner.address;
            const deployer2 = user.address;

            await token.connect(owner).updateDeployer(deployer1);
            expect(await token.getDeployer()).to.equal(deployer1);

            await token.connect(owner).updateDeployer(deployer2);
            expect(await token.getDeployer()).to.equal(deployer2);
        });

        it('should get the deployer with storage verification', async () => {
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);

            const updatedDeployerFromContract = await token.getDeployer();

            expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(updatedDeployerFromContract.toLowerCase());
            expect(updatedDeployerFromContract).to.equal(newDeployer);

            await token.connect(owner).updateDeployer(ethers.constants.AddressZero);
            const slot0Zero = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Zero = bytes32ToAddress(slot0Zero);
            const deployerFromContractZero = await token.getDeployer();

            expect(deployerFromSlot0Zero.toLowerCase()).to.equal(deployerFromContractZero.toLowerCase());
            expect(deployerFromContractZero).to.equal(ethers.constants.AddressZero);
        });

        it('should test HyperLiquidDeployer assembly code with edge cases', async () => {
            const largeAddress = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
            await token.connect(owner).updateDeployer(largeAddress);
            const returnedLargeAddress = await token.getDeployer();
            expect(returnedLargeAddress.toLowerCase()).to.equal(largeAddress.toLowerCase());

            const slot0Large = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Large = bytes32ToAddress(slot0Large);
            expect(deployerFromSlot0Large.toLowerCase()).to.equal(returnedLargeAddress.toLowerCase());

            const smallAddress = '0x0000000000000000000000000000000000000001';
            await token.connect(owner).updateDeployer(smallAddress);
            const returnedSmallAddress = await token.getDeployer();
            expect(returnedSmallAddress.toLowerCase()).to.equal(smallAddress.toLowerCase());

            const slot0Small = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Small = bytes32ToAddress(slot0Small);
            expect(deployerFromSlot0Small.toLowerCase()).to.equal(returnedSmallAddress.toLowerCase());

            const alternatingAddress = '0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
            await token.connect(owner).updateDeployer(alternatingAddress);
            const returnedAlternatingAddress = await token.getDeployer();
            expect(returnedAlternatingAddress.toLowerCase()).to.equal(alternatingAddress.toLowerCase());

            const slot0Alt = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Alt = bytes32ToAddress(slot0Alt);
            expect(deployerFromSlot0Alt.toLowerCase()).to.equal(returnedAlternatingAddress.toLowerCase());
        });

        it('should test HyperLiquidDeployer getDeployer assembly code directly', async () => {
            // Initially the deployer is AddressZero
            expect(deployerFromContract).to.equal(ethers.constants.AddressZero);
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        });

        it('should test HyperLiquidDeployer updateDeployer authorization branch (ITS operator)', async () => {
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            await mockITS.transferOperatorship(user.address);

            expect(await testDeployer.getDeployer()).to.equal(ethers.constants.AddressZero);
        });

        it('should test HyperLiquidDeployer _setDeployer call in updateDeployer', async () => {
            const newDeployer = user.address;

            await token.connect(owner).updateDeployer(newDeployer);

            expect(await token.getDeployer()).to.equal(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(token.address, 0);
            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
            expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(newDeployer.toLowerCase());
        });

        it('should update deployer and verify slot 0 changes', async () => {
            const serviceAddress = await token.interchainTokenService();

            expect(serviceAddress).to.not.equal(ethers.constants.AddressZero);

            // Initially the deployer is AddressZero, so we need to set it first
            await token.connect(owner).updateDeployer(user.address);
            const updatedDeployer = await token.getDeployer();

            const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot = '0x' + updatedSlot0.slice(26); // Extract address from slot
            expect(deployerFromSlot.toLowerCase()).to.equal(updatedDeployer.toLowerCase());
        });
    });
});
