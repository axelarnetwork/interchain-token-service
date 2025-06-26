'use strict';

const { ethers } = require('hardhat');
const { expect } = require('chai');
const { deployContract } = require('../scripts/deploy');

/**
 * Helper function to extract an address from a bytes32 storage slot
 * @param {string} slotValue - The bytes32 value from storage
 * @returns {string} The EIP-55 checksummed address
 */
function bytes32ToAddress(slotValue) {
    const addressHex = '0x' + slotValue.slice(-40);
    return ethers.utils.getAddress(addressHex);
}

describe('Slot 0 Reservation', () => {
    let hyperliquidToken;
    let owner;
    let user;
    let provider;
    let tokenAddress;
    let slot0;
    let deployerFromSlot0;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
        provider = ethers.provider;

        hyperliquidToken = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);

        tokenAddress = hyperliquidToken.address;
        slot0 = await provider.getStorageAt(tokenAddress, 0);
        deployerFromSlot0 = bytes32ToAddress(slot0);
    });

    it('should have deployerSlot0 state variable in slot 0', async () => {
        expect(deployerFromSlot0).to.equal(ethers.constants.AddressZero);
        expect(slot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });

    it('should get deployer via contract function', async () => {
        const deployer = await hyperliquidToken.deployer();
        expect(deployer).to.equal(ethers.constants.AddressZero);
    });

    it('should verify slot 0 and contract function return same value', async () => {
        const deployerFromContract = await hyperliquidToken.deployer();

        expect(deployerFromSlot0).to.equal(deployerFromContract);
        expect(deployerFromContract).to.equal(ethers.constants.AddressZero);
    });

    it('should update deployer and verify slot 0 changes', async () => {
        const initialSlot0 = slot0;

        const currentDeployer = await hyperliquidToken.deployer();
        const serviceAddress = await hyperliquidToken.interchainTokenService();

        if (currentDeployer !== ethers.constants.AddressZero) {
            const deployerSigner = await ethers.getSigner(currentDeployer);
            await hyperliquidToken.connect(deployerSigner).updateDeployer(user.address);
        } else if (serviceAddress !== ethers.constants.AddressZero) {
            const serviceSigner = await ethers.getSigner(serviceAddress);
            await hyperliquidToken.connect(serviceSigner).updateDeployer(user.address);
        } else {
            await expect(hyperliquidToken.connect(user).updateDeployer(user.address)).to.be.revertedWith('NotAuthorized');
            expect(await hyperliquidToken.deployer()).to.equal(ethers.constants.AddressZero);
            return;
        }

        const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
        const updatedDeployer = await hyperliquidToken.deployer();

        expect(updatedDeployer).to.equal(user.address);
        expect(updatedSlot0).to.not.equal(initialSlot0);

        const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
        expect(updatedDeployerFromSlot0).to.equal(user.address);
    });

    it('should verify slot 0 is reserved and not overwritten by other variables', async () => {
        const hyperliquidTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidToken.address]);
        const salt = ethers.utils.randomBytes(32);
        const tokenId = ethers.utils.randomBytes(32);

        const newTokenAddress = await hyperliquidTokenDeployer.deployedAddress(salt);
        const newToken = await ethers.getContractAt('HyperliquidInterchainToken', newTokenAddress, owner);

        await hyperliquidTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18);

        const newTokenSlot0 = await provider.getStorageAt(newTokenAddress, 0);
        const newTokenDeployerFromSlot0 = bytes32ToAddress(newTokenSlot0);
        const deployerFromContract = await newToken.deployer();

        expect(newTokenDeployerFromSlot0).to.equal(ethers.constants.AddressZero);
        expect(deployerFromContract).to.equal(ethers.constants.AddressZero);

        const tokenName = await newToken.name();
        expect(tokenName).to.equal('TestToken');

        const slot0AfterName = await provider.getStorageAt(newTokenAddress, 0);
        expect(slot0AfterName).to.equal(newTokenSlot0);
    });
});
