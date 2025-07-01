'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero },
    getContractAt,
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32 } = require('./utils');
const { deployContract, deployAll } = require('../scripts/deploy');
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
    let hyperliquidInterchainToken, hyperliquidInterchainTokenDeployer;

    const name = 'HyperliquidToken';
    const symbol = 'HLT';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let owner;
    let user;
    let provider;
    let tokenAddress;
    let slot0;
    let deployerFromSlot0;
    let deployerFromContract;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];

        hyperliquidInterchainToken = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);
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

        provider = ethers.provider;
        slot0 = await provider.getStorageAt(tokenAddress, 0);
        deployerFromSlot0 = bytes32ToAddress(slot0);
        deployerFromContract = await token.deployer();
    });

    describe('Hyperliquid Interchain Token', () => {
        it('Should calculate hardcoded constants correctly', async () => {
            await expect(deployContract(owner, 'HyperliquidInterchainToken', [owner.address])).to.not.be.reverted;
        });

        it('should verify initial deployer state and slot 0 storage', async () => {
            expect(deployerFromSlot0).to.equal(AddressZero);
            expect(deployerFromContract).to.equal(AddressZero);
            expect(slot0).to.equal('0x0000000000000000000000000000000000000000000000000000000000000000');

            const currentDeployer = await token.deployer();
            expect(deployerFromSlot0).to.equal(currentDeployer);
            expect(deployerFromSlot0.toLowerCase()).to.equal(deployerFromContract.toLowerCase());
        });

        it('should update deployer and verify storage changes', async () => {
            const initialSlot0 = slot0;
            const newDeployer = user.address;

            await token.connect(owner).updateDeployer(newDeployer);

            const updatedDeployer = await token.deployer();
            expect(updatedDeployer).to.equal(newDeployer);

            const updatedSlot0 = await provider.getStorageAt(tokenAddress, 0);
            expect(updatedSlot0).to.not.equal(initialSlot0);

            const updatedDeployerFromSlot0 = bytes32ToAddress(updatedSlot0);
            expect(updatedDeployerFromSlot0).to.equal(newDeployer);

            const serviceAddress = await token.interchainTokenService();
            expect(serviceAddress).to.not.equal(AddressZero);

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

            const token1 = await deployContract(owner, 'HyperliquidInterchainToken', [owner.address]);

            expect(await token1.deployer()).to.equal(AddressZero);

            await expect(token1.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(token1, 'NotService');

            expect(await token1.deployer()).to.equal(AddressZero);
        });

        it('should handle ITS operator scenarios', async () => {
            const TestOperator = await ethers.getContractFactory('TestOperator', owner);
            const mockITS = await TestOperator.deploy(owner.address);

            const TestHyperLiquidDeployer = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
            const testDeployer = await TestHyperLiquidDeployer.deploy(mockITS.address);

            await mockITS.transferOperatorship(user.address);

            expect(await testDeployer.deployer()).to.equal(AddressZero);

            await expect(testDeployer.connect(user).updateDeployer(user.address)).to.be.revertedWithCustomError(testDeployer, 'NotService');
        });
    });

    describe('Chain-Specific Deployment', () => {
        it('should deploy HyperliquidInterchainToken for Hyperliquid chain', async () => {
            const deployment = await deployAll(
                owner,
                'hyperliquid',
                ITS_HUB_ADDRESS,
                [],
                'HyperliquidInterchainTokenService',
                'HyperliquidInterchainTokenServiceFactory',
            );

            expect(deployment.interchainToken).to.not.be.undefined;
            expect(deployment.interchainTokenDeployer).to.not.be.undefined;

            const hyperliquidImplementation = await deployment.interchainTokenDeployer.implementationAddress();
            expect(hyperliquidImplementation).to.equal(deployment.interchainToken.address);

            const salt = ethers.utils.randomBytes(32);
            const tokenId = ethers.utils.randomBytes(32);
            const tokenAddress = await deployment.interchainTokenDeployer.deployedAddress(salt);

            await deployment.interchainTokenDeployer
                .deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18)
                .then((tx) => tx.wait());

            const token = await ethers.getContractAt('HyperliquidInterchainToken', tokenAddress, owner);
            const deployer = await token.deployer();
            expect(deployer).to.equal(AddressZero);
        });

        it('should deploy standard InterchainToken for other chains', async () => {
            const deployment = await deployAll(
                owner,
                'avalanche',
                ITS_HUB_ADDRESS,
                [],
                'StandardInterchainTokenService',
                'StandardInterchainTokenServiceFactory',
            );

            expect(deployment.interchainToken).to.not.be.undefined;
            expect(deployment.interchainTokenDeployer).to.not.be.undefined;

            const standardImplementation = await deployment.interchainTokenDeployer.implementationAddress();
            expect(standardImplementation).to.equal(deployment.interchainToken.address);

            const salt = ethers.utils.randomBytes(32);
            const tokenId = ethers.utils.randomBytes(32);
            const tokenAddress = await deployment.interchainTokenDeployer.deployedAddress(salt);

            await deployment.interchainTokenDeployer
                .deployInterchainToken(salt, tokenId, owner.address, 'TestToken', 'TEST', 18)
                .then((tx) => tx.wait());

            const token = await ethers.getContractAt('InterchainToken', tokenAddress, owner);

            expect(token.deployer).to.be.undefined;
        });
    });
});
