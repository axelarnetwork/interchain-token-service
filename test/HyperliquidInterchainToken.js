'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero },
    getContractAt,
    utils: { keccak256, toUtf8Bytes },
    provider,
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32, getEVMVersion } = require('./utils');
const { deployAll } = require('../scripts/deploy');
const { ITS_HUB_ADDRESS } = require('./constants');

function deployerStorageSlot() {
    return keccak256(toUtf8Bytes('HyperCore deployer'));
}

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
        it('should verify initial deployer state', async () => {
            const deployerFromSlot = await provider.getStorageAt(tokenAddress, deployerStorageSlot());
            const deployerFromSlotAddress = bytes32ToAddress(deployerFromSlot);
            const deployerFromContract = await token.deployer();

            expect(deployerFromSlotAddress).to.equal(AddressZero);
            expect(deployerFromContract).to.equal(AddressZero);
            expect(deployerFromSlot).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
        });

        it('should update deployer and verify storage changes', async () => {
            const newDeployer = user.address;

            await service.updateTokenDeployer(tokenId, newDeployer);

            const updatedDeployer = await token.deployer();
            expect(updatedDeployer).to.equal(newDeployer);

            const updatedDeployerSlot = await provider.getStorageAt(tokenAddress, deployerStorageSlot());
            const updatedDeployerFromSlot = bytes32ToAddress(updatedDeployerSlot);
            expect(updatedDeployerFromSlot).to.equal(newDeployer);
        });

        it('should revert when non-owner calls updateDeployer', async () => {
            const newDeployer = user.address;
            await expect(service.connect(user).updateTokenDeployer(tokenId, newDeployer)).to.be.revertedWithCustomError(
                service,
                'NotOperatorOrOwner',
            );
        });

        it('should allow the service to update deployer successfully', async () => {
            const newDeployer = user.address;
            await service.updateTokenDeployer(tokenId, newDeployer);
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
        it('should preserve the same bytecode', async () => {
            const contract = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const contractBytecode = contract.bytecode;
            const contractBytecodeHash = keccak256(contractBytecode);

            const expected = {
                london: '0x3d3a40c01246474610c271813635f03c57ced468a24b8ca2313a34b3cb8d3467',
            }[getEVMVersion()];

            expect(contractBytecodeHash).to.be.equal(expected);
        });
    });
});
