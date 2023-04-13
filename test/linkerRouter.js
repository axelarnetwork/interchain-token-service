'use strict';

require('dotenv').config();
const chai = require('chai');
const { getDefaultProvider, Wallet } = require('ethers');
const { expect } = chai;
const { keccak256, defaultAbiCoder } = require('ethers/lib/utils');
const { createAndExport, stopAll } = require('@axelar-network/axelar-local-dev');

let chain;
let wallet;
let otherWallet;
let linkerRouter;
let interChainTokenServiceAddress;
const otherRemoteAddress = 'any string as an address';
const otherChain = 'Chain Name';

async function setupLocal(toFund) {
    await createAndExport({
        chainOutputPath: './info/local1.json',
        accountsToFund: toFund,
        relayInterval: 100,
        chains: ['Ethereum'],
        port: 8501,
    });
    chain = require('../info/local1.json')[0];
}

describe('LinkerRouter', () => {
    before(async () => {
        const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
        const otherKey = keccak256(defaultAbiCoder.encode(['string'], ['another key']));
        const deployerAddress = new Wallet(deployerKey).address;
        const otherAddress = new Wallet(otherKey).address;
        const toFund = [deployerAddress, otherAddress];
        await setupLocal(toFund);
        const provider = getDefaultProvider(chain.rpc);
        wallet = new Wallet(deployerKey, provider);
        otherWallet = new Wallet(otherKey, provider);
        const { deployLinkerRouter } = require('../scripts/deploy.js');

        linkerRouter = await deployLinkerRouter(chain, wallet);
        interChainTokenServiceAddress = await linkerRouter.interChainTokenServiceAddress();
    });

    after(async () => {
        await stopAll();
    });

    it('Should get the correct remote address for unregistered chains', async () => {
        const remoteAddress = await linkerRouter.getRemoteAddress(otherChain);
        expect(remoteAddress).to.equal(interChainTokenServiceAddress.toLowerCase());
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await linkerRouter.validateSender(otherChain, interChainTokenServiceAddress)).to.equal(true);
    });

    it('Should not be able to add a custom remote address as not the owner', async () => {
        await expect(linkerRouter.connect(otherWallet).addTrustedAddress(otherChain, otherRemoteAddress)).to.be.reverted;
    });

    it('Should be able to add a custom remote address as the owner', async () => {
        await linkerRouter.addTrustedAddress(otherChain, otherRemoteAddress);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(otherRemoteAddress);
    });
    it('Should be able to validate remote addresses properly.', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(true);
        expect(await linkerRouter.validateSender(otherChain, interChainTokenServiceAddress)).to.equal(false);
    });

    it('Should not be able to remove a custom remote address as not the owner', async () => {
        await expect(linkerRouter.connect(otherWallet).removeTrustedAddress(otherChain)).to.be.reverted;
    });

    it('Should be able to remove a custom remote address as the owner', async () => {
        await linkerRouter.removeTrustedAddress(otherChain);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(interChainTokenServiceAddress.toLowerCase());
    });

    it('Should be able to validate remote addresses properly.', async () => {
        expect(await linkerRouter.validateSender(otherChain, otherRemoteAddress)).to.equal(false);
        expect(await linkerRouter.validateSender(otherChain, interChainTokenServiceAddress)).to.equal(true);
    });

    it('Should have chains as not gateway supported by default', async () => {
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });

    it('Should not be able to add a chain as gateway supported as not the onwer', async () => {
        await expect(linkerRouter.connect(otherWallet).addGatewaySupportedChains([otherChain])).to.be.reverted;
    });

    it('Should be able to add a chain as gateway supported as the onwer', async () => {
        await linkerRouter.addGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(true);
    });

    it('Should not be able to remove a chain as gateway supported as not the onwer', async () => {
        await expect(linkerRouter.connect(otherWallet).removeGatewaySupportedChains([otherChain])).to.be.reverted;
    });

    it('Should be able to remove a chain as gateway supported as the onwer', async () => {
        await linkerRouter.removeGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });
});
