'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    utils: { toUtf8Bytes, defaultAbiCoder },
    constants: { AddressZero },
} = ethers;
const { expect } = chai;
const { expectRevert } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('Token Manager', () => {
    let owner, user, token, service, liquidityPool;
    let tokenManagerLockUnlock, tokenManagerMintBurn, tokenManagerLiquidityPool, tokenManagerLockUnlockFeeOnTransfer;

    before(async () => {
        [owner, user, token, service, liquidityPool] = await ethers.getSigners();

        tokenManagerLockUnlock = await deployContract(owner, `TokenManagerLockUnlock`, [service.address]);
        tokenManagerMintBurn = await deployContract(owner, `TokenManagerMintBurn`, [service.address]);
        tokenManagerLiquidityPool = await deployContract(owner, `TokenManagerLiquidityPool`, [service.address]);
        tokenManagerLockUnlockFeeOnTransfer = await deployContract(owner, `TokenManagerLockUnlockFee`, [service.address]);
    });

    it('Should calculate hardcoded constants correctly', async () => {
        await expect(deployContract(owner, `TestTokenManager`, [service.address])).to.not.be.reverted;
    });

    it('Should revert on token manager deployment with invalid service address', async () => {
        await expectRevert(
            (gasOptions) => deployContract(owner, `TokenManagerLockUnlock`, [AddressZero, gasOptions]),
            tokenManagerLockUnlock,
            'TokenLinkerZeroAddress',
        );
    });

    it('Should revert on setup if not called by the proxy', async () => {
        const params = '0x';
        await expectRevert((gasOptions) => tokenManagerLockUnlock.setup(params, gasOptions), tokenManagerLockUnlock, 'NotProxy');
    });

    it('Should revert on transmitInterchainTransfer if not called by the token', async () => {
        const sender = owner.address;
        const destinationChain = 'Dest Chain';
        const destinationAddress = toUtf8Bytes(user.address);
        const amount = 10;
        const metadata = '0x00000000';

        await expectRevert(
            (gasOptions) =>
                tokenManagerLockUnlock.transmitInterchainTransfer(
                    sender,
                    destinationChain,
                    destinationAddress,
                    amount,
                    metadata,
                    gasOptions,
                ),
            tokenManagerLockUnlock,
            'NotToken',
        );
    });

    it('Should revert on giveToken if not called by the service', async () => {
        const destinationAddress = user.address;
        const amount = 10;

        await expectRevert(
            (gasOptions) => tokenManagerLockUnlock.giveToken(destinationAddress, amount, gasOptions),
            tokenManagerLockUnlock,
            'NotService',
        );
    });

    it('Should revert on takeToken if not called by the service', async () => {
        const sourceAddress = user.address;
        const amount = 10;

        await expectRevert(
            (gasOptions) => tokenManagerLockUnlock.takeToken(sourceAddress, amount, gasOptions),
            tokenManagerLockUnlock,
            'NotService',
        );
    });

    it('Should revert on setFlowLimit if not called by the operator', async () => {
        const flowLimit = 100;

        await expectRevert(
            (gasOptions) => tokenManagerLockUnlock.setFlowLimit(flowLimit, gasOptions),
            tokenManagerLockUnlock,
            'MissingRole',
        );
    });

    it('Should return the correct parameters for lock/unlock token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerLockUnlock.getParams(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should return the correct parameters for mint/burn token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerMintBurn.getParams(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should return the correct parameters for liquidity pool token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(
            ['bytes', 'address', 'address'],
            [toUtf8Bytes(owner.address), token.address, liquidityPool.address],
        );
        const params = await tokenManagerLiquidityPool.getParams(toUtf8Bytes(owner.address), token.address, liquidityPool.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should return the correct parameters for fee on transfer token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerLockUnlockFeeOnTransfer.getParams(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });
});
