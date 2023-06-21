'use strict';

require('dotenv').config();
const chai = require('chai');
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { expect } = chai;
const { deployLinkerRouter } = require('../scripts/deploy');

describe('LinkerRouter', () => {
    let ownerWallet, otherWallet, linkerRouter, interchainTokenServiceAddress;

    const otherRemoteAddress = 'any string as an address';
    const otherChain = 'Chain Name';
    before(async () => {
        const wallets = await ethers.getSigners();
        ownerWallet = wallets[0];
        otherWallet = wallets[1];
        interchainTokenServiceAddress = wallets[2].address;
        linkerRouter = await deployLinkerRouter(ownerWallet, interchainTokenServiceAddress);
    });

    it('Should revert on LinkerRouter deployment with invalid interchain token service address', async () => {
        const linkerRouterFactory = await ethers.getContractFactory('LinkerRouter');
        await expect(linkerRouterFactory.deploy(AddressZero, [], [])).to.be.revertedWithCustomError(linkerRouter, 'ZeroAddress');
    });

    it('Should revert on LinkerRouter deployment with length mismatch between chains and trusted addresses arrays', async () => {
        const linkerRouterFactory = await ethers.getContractFactory('LinkerRouter');
        await expect(linkerRouterFactory.deploy(interchainTokenServiceAddress, ['Chain A'], [])).to.be.revertedWithCustomError(
            linkerRouter,
            'LengthMismatch',
        );
    });

    it('Should get the correct remote address for unregistered chains', async () => {
        const remoteAddress = await linkerRouter.getRemoteAddress(otherChain);
        expect(remoteAddress).to.equal(interchainTokenServiceAddress.toLowerCase());
    });

    it('Should be able to validate remote addresses properly', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await linkerRouter.validateSender(otherChain, interchainTokenServiceAddress)).to.equal(true);
    });

    it('Should not be able to add a custom remote address as not the owner', async () => {
        await expect(linkerRouter.connect(otherWallet).addTrustedAddress(otherChain, otherRemoteAddress)).to.be.revertedWithCustomError(
            linkerRouter,
            'NotOwner',
        );
    });

    it('Should be able to add a custom remote address as the owner', async () => {
        await linkerRouter.addTrustedAddress(otherChain, otherRemoteAddress);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(otherRemoteAddress);
    });

    it('Should revert on adding a custom remote address with an empty chain name', async () => {
        await expect(linkerRouter.addTrustedAddress('', otherRemoteAddress)).to.be.revertedWithCustomError(
            linkerRouter,
            'ZeroStringLength',
        );
    });

    it('Should revert on adding a custom remote address with an invalid remote address', async () => {
        await expect(linkerRouter.addTrustedAddress(otherChain, '')).to.be.revertedWithCustomError(linkerRouter, 'ZeroStringLength');
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(true);
    });

    it('Should not be able to remove a custom remote address as not the owner', async () => {
        await expect(linkerRouter.connect(otherWallet).removeTrustedAddress(otherChain)).to.be.revertedWithCustomError(
            linkerRouter,
            'NotOwner',
        );
    });

    it('Should be able to remove a custom remote address as the owner', async () => {
        await linkerRouter.removeTrustedAddress(otherChain);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(interchainTokenServiceAddress.toLowerCase());
    });

    it('Should revert on removing a custom remote address with an empty chain name', async () => {
        await expect(linkerRouter.removeTrustedAddress('')).to.be.revertedWithCustomError(linkerRouter, 'ZeroStringLength');
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await linkerRouter.validateSender(otherChain, interchainTokenServiceAddress)).to.equal(true);
    });

    it('Should have chains as not gateway supported by default', async () => {
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });

    it('Should not be able to add a chain as gateway supported as not the onwer', async () => {
        await expect(linkerRouter.connect(otherWallet).addGatewaySupportedChains([otherChain])).to.be.revertedWithCustomError(
            linkerRouter,
            'NotOwner',
        );
    });

    it('Should be able to add a chain as gateway supported as the onwer', async () => {
        await linkerRouter.addGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(true);
    });

    it('Should not be able to remove a chain as gateway supported as not the onwer', async () => {
        await expect(linkerRouter.connect(otherWallet).removeGatewaySupportedChains([otherChain])).to.be.revertedWithCustomError(
            linkerRouter,
            'NotOwner',
        );
    });

    it('Should be able to remove a chain as gateway supported as the onwer', async () => {
        await linkerRouter.removeGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });
});
