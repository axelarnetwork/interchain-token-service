'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero },
    getContractAt,
    utils: { keccak256 },
    provider,
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32, getEVMVersion } = require('./utils');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

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
    let service, tokenFactory;
    let token;
    let owner;
    let user;
    let tokenAddress;
    let tokenId;

    beforeEach(async () => {
        const wallets = await ethers.getSigners();
        const salt = getRandomBytes32();

        owner = wallets[0];
        user = wallets[1];

        const deployment = await deployAll(
            owner,
            'hyperliquid',
            ITS_HUB_ADDRESS,
            [],
            'HyperliquidInterchainTokenService',
            'HyperliquidInterchainTokenServiceFactory',
        );

        service = deployment.service;
        tokenFactory = deployment.tokenFactory;

        await tokenFactory.deployInterchainToken(salt, 'TestToken', 'TEST', 18, 1000000, owner.address).then((tx) => tx.wait());
        tokenId = await tokenFactory.interchainTokenId(owner.address, salt);
        tokenAddress = await service.registeredTokenAddress(tokenId);
        token = await getContractAt('HyperliquidInterchainToken', tokenAddress, owner);
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

            await service.connect(owner).updateTokenDeployer(tokenId, newDeployer);

            const updatedDeployer = await token.deployer();
            expect(updatedDeployer).to.equal(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);

            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
            expect(updatedDeployerFromSlot0).to.equal(newDeployer);

            const deployerFromSlot = '0x' + updatedSlot0.slice(26);
            expect(deployerFromSlot.toLowerCase()).to.equal(updatedDeployer.toLowerCase());
        });

        it('should verify slot 0 is reserved and not overwritten by other variables', async () => {
            const newSalt = getRandomBytes32();
            await tokenFactory.deployInterchainToken(newSalt, 'TestToken2', 'TEST2', 18, 1000000, owner.address).then((tx) => tx.wait());
            const newTokenId = await tokenFactory.interchainTokenId(owner.address, newSalt);
            const newTokenAddress = await service.registeredTokenAddress(newTokenId);
            const newToken = await ethers.getContractAt('HyperliquidInterchainToken', newTokenAddress, owner);

            const newTokenSlot0 = await provider.getStorageAt(newTokenAddress, 0);
            const newTokenDeployerFromSlot0 = bytes32ToAddress(newTokenSlot0);
            const deployerFromContract = await newToken.deployer();

            expect(newTokenDeployerFromSlot0).to.equal(AddressZero);
            expect(deployerFromContract).to.equal(AddressZero);

            const tokenName = await newToken.name();
            expect(tokenName).to.equal('TestToken2');

            const slot0AfterName = await provider.getStorageAt(newTokenAddress, 0);
            expect(slot0AfterName).to.equal(newTokenSlot0);
        });

        it('should update deployer with multiple different addresses and verify storage', async () => {
            const wallets = await ethers.getSigners();
            const addresses = [owner.address, user.address, AddressZero, wallets[2].address, wallets[3].address];

            for (const addr of addresses) {
                await service.connect(owner).updateTokenDeployer(tokenId, addr);
                expect(await token.deployer()).to.equal(addr);

                const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
                const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
                expect(updatedDeployerFromSlot0.toLowerCase()).to.equal(addr.toLowerCase());
            }

            await service.connect(owner).updateTokenDeployer(tokenId, AddressZero);
            const slot0Zero = await provider.getStorageAt(tokenAddress, 0);
            const deployerFromSlot0Zero = bytes32ToAddress(slot0Zero);
            const deployerFromContractZero = await token.deployer();

            expect(deployerFromSlot0Zero.toLowerCase()).to.equal(deployerFromContractZero.toLowerCase());
            expect(deployerFromContractZero).to.equal(AddressZero);
        });

        it('should revert when non-owner calls updateDeployer', async () => {
            const newDeployer = user.address;
            await expect(service.connect(user).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should revert when non-owner calls updateDeployer after deployer has been set', async () => {
            const newDeployer = user.address;
            await service.connect(owner).updateTokenDeployer(tokenId, newDeployer);
            await expect(service.connect(user).updateTokenDeployer(tokenId, user.address)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should allow the service to update deployer successfully', async () => {
            const newDeployer = user.address;
            await service.connect(owner).updateTokenDeployer(tokenId, newDeployer);
            expect(await token.deployer()).to.equal(newDeployer);
        });

        it('should revert when non-service calls updateDeployer directly on token', async () => {
            const newDeployer = user.address;
            await expect(token.connect(owner).updateDeployer(newDeployer))
                .to.be.revertedWithCustomError(token, 'NotService')
                .withArgs(owner.address);
        });
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        // This test ensures the contract bytecode remains consistent across deployments
        // to allow for upgradability of ITS without breaking existing tokens
        it('Should preserve the same bytecode', async () => {
            const contract = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const contractBytecode = contract.bytecode;
            const contractBytecodeHash = keccak256(contractBytecode);

            const expected = {
                london: '0x4f8c7fe60a682456463ec110bfb42c230eb586a43148a93473b1aea18b7c55db',
            }[getEVMVersion()];

            expect(contractBytecodeHash).to.be.equal(expected);
        });
    });
});
