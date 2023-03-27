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
const otherChain = 'Chain Name';

async function setupLocal(toFund) {
    await createAndExport({
        chainOutputPath: './info/local.json',
        accountsToFund: toFund,
        relayInterval: 100,
        chains: ['Ethereum'],
        port: 8501,
    });
    chain = require('../info/local.json')[0];
}

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

describe('Token', () => {
    it('Should get the correct remote address for unregistered chains', async () => {
        const remoteAddress = await linkerRouter.getRemoteAddress(otherChain);
        expect(remoteAddress).to.equal(interChainTokenServiceAddress.toLowerCase());
    });
    it('Should not be able to add a custom remote address as not the owner', async () => {
        const remoteAddress = 'any string as an address';
        expect(linkerRouter.connect(otherWallet).addTrustedAddress(otherChain, remoteAddress)).to.be.revertedWith('NotOwner()');
    });
    it('Should be able to add a custom remote address as the owner', async () => {
        const remoteAddress = 'any string as an address';
        await linkerRouter.addTrustedAddress(otherChain, remoteAddress);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(remoteAddress);
    });
    it('Should not be able to remove a custom remote address as not the owner', async () => {
        expect(linkerRouter.connect(otherWallet).removeTrustedAddress(otherChain)).to.be.revertedWith('NotOwner()');
    });
    it('Should be able to remove a custom remote address as the owner', async () => {
        await linkerRouter.removeTrustedAddress(otherChain);
        expect(await linkerRouter.getRemoteAddress(otherChain)).to.equal(interChainTokenServiceAddress.toLowerCase());
    });

    it('Should have chains as not gateway supported by default', async () => {
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });

    it('Should not be able to add a chain as gateway supported as not the onwer', async () => {
        expect(linkerRouter.connect(otherWallet).addGatewaySupportedChains([otherChain])).to.be.revertedWith('NotOwner()');
    });
    it('Should be able to add a chain as gateway supported as the onwer', async () => {
        await linkerRouter.addGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(true);
    });
    it('Should not be able to remove a chain as gateway supported as not the onwer', async () => {
        expect(linkerRouter.connect(otherWallet).removeGatewaySupportedChains([otherChain])).to.be.revertedWith('NotOwner()');
    });
    it('Should be able to remove a chain as gateway supported as the onwer', async () => {
        await linkerRouter.removeGatewaySupportedChains([otherChain]);
        expect(await linkerRouter.supportedByGateway(otherChain)).to.equal(false);
    });
});
