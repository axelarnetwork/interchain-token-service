'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    getContractAt,
    utils: { keccak256, toUtf8Bytes },
} = ethers;
const { expect } = chai;
const { getRandomBytes32, expectRevert, getGasOptions } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('InterchainToken', () => {
    let interchainToken, interchainTokenDeployer;

    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let tokenProxy;

    let owner;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];

        interchainToken = await deployContract(owner, 'InterchainToken');
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [interchainToken.address]);

        const salt = getRandomBytes32();

        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('InterchainToken', tokenAddress, owner);
        tokenProxy = await getContractAt('InterchainTokenProxy', tokenAddress, owner);

        await interchainTokenDeployer
            .deployInterchainToken(salt, owner.address, owner.address, name, symbol, decimals)
            .then((tx) => tx.wait());

        await (await token.mint(owner.address, mintAmount)).wait();
    });

    describe('Interchain Token', () => {
        it('revert on init if not called by the proxy', async () => {
            const implementationAddress = await interchainTokenDeployer.implementationAddress();
            const implementation = await getContractAt('InterchainToken', implementationAddress, owner);

            const tokenManagerAddress = owner.address;
            const distributor = owner.address;
            const tokenName = 'name';
            const tokenSymbol = 'symbol';
            const tokenDecimals = 7;
            await expectRevert((gasOptions) => implementation.init(tokenManagerAddress, distributor, tokenName, tokenSymbol, tokenDecimals, gasOptions), implementation, 'AlreadySetup');
        });
    });
});
