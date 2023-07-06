'use strict';

require('dotenv').config();
const chai = require('chai');
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder } = ethers.utils;
const { expect } = chai;
const { deployRemoteAddressValidator, deployContract } = require('../scripts/deploy');

describe('RemoteAddressValidator', () => {
    let ownerWallet, otherWallet, remoteAddressValidator, interchainTokenServiceAddress;

    const otherRemoteAddress = 'any string as an address';
    const otherChain = 'Chain Name';
    before(async () => {
        const wallets = await ethers.getSigners();
        ownerWallet = wallets[0];
        otherWallet = wallets[1];
        interchainTokenServiceAddress = wallets[2].address;
        remoteAddressValidator = await deployRemoteAddressValidator(ownerWallet, interchainTokenServiceAddress);
    });

    it('Should revert on RemoteAddressValidator deployment with invalid interchain token service address', async () => {
        const remoteAddressValidatorFactory = await ethers.getContractFactory('RemoteAddressValidator');
        await expect(remoteAddressValidatorFactory.deploy(AddressZero)).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'ZeroAddress',
        );
    });

    it('Should revert on RemoteAddressValidator deployment with length mismatch between chains and trusted addresses arrays', async () => {
        const remoteAddressValidatorImpl = await deployContract(ownerWallet, 'RemoteAddressValidator', [interchainTokenServiceAddress]);
        const remoteAddressValidatorProxyFactory = await ethers.getContractFactory('RemoteAddressValidatorProxy');
        const params = defaultAbiCoder.encode(['string[]', 'string[]'], [['Chain A'], []]);
        await expect(
            remoteAddressValidatorProxyFactory.deploy(remoteAddressValidatorImpl.address, ownerWallet.address, params),
        ).to.be.revertedWithCustomError(remoteAddressValidator, 'SetupFailed');
    });

    it('Should get the correct remote address for unregistered chains', async () => {
        const remoteAddress = await remoteAddressValidator.getRemoteAddress(otherChain);
        expect(remoteAddress).to.equal(interchainTokenServiceAddress.toLowerCase());
    });

    it('Should be able to validate remote addresses properly', async () => {
        expect(await remoteAddressValidator.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await remoteAddressValidator.validateSender(otherChain, interchainTokenServiceAddress)).to.equal(true);
    });

    it('Should not be able to add a custom remote address as not the owner', async () => {
        await expect(
            remoteAddressValidator.connect(otherWallet).addTrustedAddress(otherChain, otherRemoteAddress),
        ).to.be.revertedWithCustomError(remoteAddressValidator, 'NotOwner');
    });

    it('Should be able to add a custom remote address as the owner', async () => {
        await expect(remoteAddressValidator.addTrustedAddress(otherChain, otherRemoteAddress))
            .to.emit(remoteAddressValidator, 'TrustedAddressAdded')
            .withArgs(otherChain, otherRemoteAddress);
        expect(await remoteAddressValidator.getRemoteAddress(otherChain)).to.equal(otherRemoteAddress);
    });

    it('Should revert on adding a custom remote address with an empty chain name', async () => {
        await expect(remoteAddressValidator.addTrustedAddress('', otherRemoteAddress)).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'ZeroStringLength',
        );
    });

    it('Should revert on adding a custom remote address with an invalid remote address', async () => {
        await expect(remoteAddressValidator.addTrustedAddress(otherChain, '')).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'ZeroStringLength',
        );
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await remoteAddressValidator.validateSender(otherChain, otherRemoteAddress)).to.equal(true);
    });

    it('Should not be able to remove a custom remote address as not the owner', async () => {
        await expect(remoteAddressValidator.connect(otherWallet).removeTrustedAddress(otherChain)).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'NotOwner',
        );
    });

    it('Should be able to remove a custom remote address as the owner', async () => {
        await expect(remoteAddressValidator.removeTrustedAddress(otherChain))
            .to.emit(remoteAddressValidator, 'TrustedAddressRemoved')
            .withArgs(otherChain);
        expect(await remoteAddressValidator.getRemoteAddress(otherChain)).to.equal(interchainTokenServiceAddress.toLowerCase());
    });

    it('Should revert on removing a custom remote address with an empty chain name', async () => {
        await expect(remoteAddressValidator.removeTrustedAddress('')).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'ZeroStringLength',
        );
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await remoteAddressValidator.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await remoteAddressValidator.validateSender(otherChain, interchainTokenServiceAddress)).to.equal(true);
    });

    it('Should have chains as not gateway supported by default', async () => {
        expect(await remoteAddressValidator.supportedByGateway(otherChain)).to.equal(false);
    });

    it('Should not be able to add a chain as gateway supported as not the onwer', async () => {
        await expect(remoteAddressValidator.connect(otherWallet).addGatewaySupportedChains([otherChain])).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'NotOwner',
        );
    });

    it('Should be able to add a chain as gateway supported as the onwer', async () => {
        await expect(remoteAddressValidator.addGatewaySupportedChains([otherChain]))
            .to.emit(remoteAddressValidator, 'GatewaySupportedChainAdded')
            .withArgs(otherChain);
        expect(await remoteAddressValidator.supportedByGateway(otherChain)).to.equal(true);
    });

    it('Should not be able to remove a chain as gateway supported as not the onwer', async () => {
        await expect(remoteAddressValidator.connect(otherWallet).removeGatewaySupportedChains([otherChain])).to.be.revertedWithCustomError(
            remoteAddressValidator,
            'NotOwner',
        );
    });

    it('Should be able to remove a chain as gateway supported as the onwer', async () => {
        await expect(remoteAddressValidator.removeGatewaySupportedChains([otherChain]))
            .to.emit(remoteAddressValidator, 'GatewaySupportedChainRemoved')
            .withArgs(otherChain);
        expect(await remoteAddressValidator.supportedByGateway(otherChain)).to.equal(false);
    });
});
