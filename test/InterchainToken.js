'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero, HashZero },
    getContractAt,
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32, expectRevert } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('InterchainToken', () => {
    let interchainToken, interchainTokenDeployer;

    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    let token;

    let owner;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];

        interchainToken = await deployContract(owner, 'InterchainToken', [owner.address]);
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [interchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('InterchainToken', tokenAddress, owner);

        await interchainTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals).then((tx) => tx.wait());

        await (await token.mint(owner.address, mintAmount)).wait();
        expect(await token.interchainTokenId()).to.equal(tokenId);
    });

    describe('Interchain Token', () => {
        it('revert on init if not called by the proxy', async () => {
            const implementationAddress = await interchainTokenDeployer.implementationAddress();
            const implementation = await getContractAt('InterchainToken', implementationAddress, owner);

            const tokenId = getRandomBytes32();
            const distributor = owner.address;
            const tokenName = 'name';
            const tokenSymbol = 'symbol';
            const tokenDecimals = 7;
            await expectRevert(
                (gasOptions) => implementation.init(tokenId, distributor, tokenName, tokenSymbol, tokenDecimals, gasOptions),
                implementation,
                'AlreadyInitialized',
            );
        });

        it('revert on init if service is address(0)', async () => {
            await expectRevert(
                (gasOptions) => deployContract(owner, 'InterchainToken', [AddressZero, gasOptions]),
                interchainToken,
                'InterchainTokenServiceAddressZero',
            );
        });

        it('revert on init if tokenId is 0', async () => {
            const implementationAddress = await interchainTokenDeployer.implementationAddress();
            const implementation = await getContractAt('InterchainToken', implementationAddress, owner);

            const salt = getRandomBytes32();
            const distributor = owner.address;
            await expectRevert(
                (gasOptions) =>
                    interchainTokenDeployer.deployInterchainToken(salt, HashZero, distributor, name, symbol, decimals, gasOptions),
                implementation,
                'TokenIdZero',
            );
        });

        it('revert on init if token name is invalid', async () => {
            const implementationAddress = await interchainTokenDeployer.implementationAddress();
            const implementation = await getContractAt('InterchainToken', implementationAddress, owner);

            const salt = getRandomBytes32();
            const tokenId = getRandomBytes32();
            const distributor = owner.address;
            await expectRevert(
                (gasOptions) => interchainTokenDeployer.deployInterchainToken(salt, tokenId, distributor, '', symbol, decimals, gasOptions),
                implementation,
                'TokenNameEmpty',
            );
        });
    });
});
