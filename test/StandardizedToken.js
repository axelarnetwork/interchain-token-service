'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    Contract,
    utils: { keccak256, toUtf8Bytes },
} = ethers;
const { expect } = chai;
const { getRandomBytes32, expectRevert, getGasOptions } = require('./utils');
const { deployContract } = require('../scripts/deploy');

const StandardizedToken = require('../artifacts/contracts/token-implementations/StandardizedToken.sol/StandardizedToken.json');
const StandardizedTokenProxy = require('../artifacts/contracts/proxies/StandardizedTokenProxy.sol/StandardizedTokenProxy.json');

describe('StandardizedToken', () => {
    let standardizedToken, interchainTokenDeployer;

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

        standardizedToken = await deployContract(owner, 'StandardizedToken');
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [standardizedToken.address]);

        const salt = getRandomBytes32();

        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        token = new Contract(tokenAddress, StandardizedToken.abi, owner);
        tokenProxy = new Contract(tokenAddress, StandardizedTokenProxy.abi, owner);

        await interchainTokenDeployer
            .deployInterchainToken(salt, owner.address, owner.address, name, symbol, decimals)
            .then((tx) => tx.wait());

        await (await token.mint(owner.address, mintAmount)).wait();
    });

    describe('Standardized Token Proxy', () => {
        it('should revert if standardized token implementation is invalid', async () => {
            const invalidStandardizedToken = await deployContract(owner, 'InvalidStandardizedToken');
            interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [invalidStandardizedToken.address]);

            const salt = getRandomBytes32();

            await expect(
                interchainTokenDeployer.deployInterchainToken(salt, owner.address, owner.address, name, symbol, decimals, getGasOptions()),
            ).to.be.reverted;
        });

        it('should revert if standardized token setup fails', async () => {
            const params = '0x1234';
            await expectRevert(
                (gasOptions) => deployContract(owner, 'StandardizedTokenProxy', [standardizedToken.address, params, gasOptions]),
                tokenProxy,
                'SetupFailed',
            );
        });

        it('should return the correct contract ID', async () => {
            const contractID = await token.contractId();
            const hash = keccak256(toUtf8Bytes('standardized-token'));
            expect(contractID).to.equal(hash);
        });
    });

    describe('Standardized Token', () => {
        it('revert on setup if not called by the proxy', async () => {
            const implementationAddress = await tokenProxy.implementation();
            const implementation = new Contract(implementationAddress, StandardizedToken.abi, owner);

            const params = '0x';
            await expectRevert((gasOptions) => implementation.setup(params, gasOptions), token, 'NotProxy');
        });
    });
});
