'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero },
    getContractAt,
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32 } = require('./utils');
const { deployContract } = require('../scripts/deploy');

const provider = ethers.provider;

/**
 * Convert bytes32 value to EIP-55 address
 * @param {string} bytes - The bytes32 value
 * @returns {string} The EIP-55 checksummed address
 */
function bytes32ToAddress(bytes) {
    const addressHex = '0x' + bytes.slice(-40);
    return ethers.utils.getAddress(addressHex);
}

describe('HyperliquidInterchainToken', () => {
    let hyperliquidInterchainToken, hyperliquidInterchainTokenDeployer;

    const name = 'HyperliquidToken';
    const symbol = 'HLT';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let owner;
    let user;
    let tokenAddress;

    beforeEach(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];

        token = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
        hyperliquidInterchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidInterchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        tokenAddress = await hyperliquidInterchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('HyperliquidInterchainToken', tokenAddress, owner);

        await hyperliquidInterchainTokenDeployer
            .deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals)
            .then((tx) => tx.wait());

        await token.mint(owner.address, mintAmount).then((tx) => tx.wait());
        expect(await token.interchainTokenId()).to.equal(tokenId);
    });

    describe('Hyperliquid Interchain Token', () => {
        it('should verify initial deployer state and slot 0 storage', async () => {
            const slot0 = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0 = bytes32ToAddress(slot0);
            const deployerFromContract = await token.deployer();

            expect(deployerFromSlot0).to.equal(AddressZero);
            expect(deployerFromContract).to.equal(AddressZero);
            expect(slot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');

            const currentDeployer = await token.deployer();
            expect(deployerFromSlot0).to.equal(currentDeployer);
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        });

        it('should update deployer and verify storage changes', async () => {
            const newDeployer = user.address;

            await token.connect(owner).updateDeployer(newDeployer);

            const updatedDeployer = await token.deployer();
            expect(updatedDeployer).to.equal(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);

            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
            expect(updatedDeployerFromSlot0).to.equal(newDeployer);

            const deployerFromSlot = '0x' + updatedSlot0.slice(26);
            expect(deployerFromSlot.toLowerCase()).to.equal(updatedDeployer.toLowerCase());
        });

        it('should verify slot 0 is reserved and not overwritten by other variables', async () => {
            const hyperliquidTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [hyperliquidInterchainToken.address]);
            const salt = ethers.utils.randomBytes(32);
            const tokenId = ethers.utils.randomBytes(32);

            const newTokenAddress = await hyperliquidTokenDeployer.deployedAddress(salt);
            const newToken = await ethers.getContractAt('HyperliquidInterchainToken', newTokenAddress, owner);

            await hyperliquidTokenDeployer
                .deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18)
                .then((tx) => tx.wait());

            const newTokenSlot0 = await provider.getStorageAt(newTokenAddress, 0);
            const newTokenDeployerFromSlot0 = bytes32ToAddress(newTokenSlot0);
            const deployerFromContract = await newToken.deployer();

            expect(newTokenDeployerFromSlot0).to.equal(AddressZero);
            expect(deployerFromContract).to.equal(AddressZero);

            const tokenName = await newToken.name();
            expect(tokenName).to.equal('TestToken');

            const slot0AfterName = await provider.getStorageAt(newTokenAddress, 0);
            expect(slot0AfterName).to.equal(newTokenSlot0);
        });

        it('should update deployer with multiple different addresses and verify storage', async () => {
            const wallets = await ethers.getSigners();
            const addresses = [owner.address, user.address, AddressZero, wallets[2].address, wallets[3].address];

            for (const addr of addresses) {
                await token.connect(owner).updateDeployer(addr);
                expect(await token.deployer()).to.equal(addr);

                const updatedSlot0 = await provider.getStorageAt(token.address, 0);
                const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
                expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(addr.toLowerCase());
            }

            await token.connect(owner).updateDeployer(AddressZero);
            const slot0Zero = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Zero = bytes32ToAddress(slot0Zero);
            const deployerFromContractZero = await token.deployer();

            expect(deployerFromSlot0Zero.toLowerCase()).to.equal(deployerFromContractZero.toLowerCase());
            expect(deployerFromContractZero).to.equal(AddressZero);
        });

        it('should handle authorization and access control', async () => {
            const newDeployer = user.address;
            await token.connect(owner).updateDeployer(newDeployer);
            expect(await token.deployer()).to.equal(newDeployer);
            await expect(token.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(token, 'NotService');
        });

        it('should prevent unauthorized deployer updates on fresh token deployment', async () => {
            const token = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);

            expect(await token.deployer()).to.equal(AddressZero);

            await expect(token.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(token, 'NotService');

            expect(await token.deployer()).to.equal(AddressZero);
        });
    });
});
