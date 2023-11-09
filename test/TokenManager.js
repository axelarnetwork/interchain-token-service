'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    utils: { keccak256, toUtf8Bytes, defaultAbiCoder },
    constants: { AddressZero },
} = ethers;
const { expect } = chai;
const { expectRevert } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('Token Manager', () => {
    const FLOW_LIMITER_ROLE = 2;
    let owner, user, token, service;
    let tokenManagerTest, tokenManagerLockUnlock, tokenManagerMintBurn, tokenManagerLockUnlockFeeOnTransfer;

    before(async () => {
        [owner, user, token, service] = await ethers.getSigners();

        tokenManagerTest = await deployContract(owner, `TokenManagerTest`, [service.address]);
        tokenManagerLockUnlock = await deployContract(owner, `TokenManagerLockUnlock`, [service.address]);
        tokenManagerMintBurn = await deployContract(owner, `TokenManagerMintBurn`, [service.address]);
        tokenManagerLockUnlockFeeOnTransfer = await deployContract(owner, `TokenManagerLockUnlockFee`, [service.address]);
    });

    it('Should calculate hardcoded constants correctly', async () => {
        await expect(deployContract(owner, `TestTokenManager`, [service.address])).to.not.be.reverted;
    });

    it('Should revert on token manager deployment with invalid service address', async () => {
        await expectRevert(
            (gasOptions) => deployContract(owner, `TokenManagerTest`, [AddressZero, gasOptions]),
            tokenManagerTest,
            'TokenLinkerZeroAddress',
        );
    });

    it('Should return the correct contract id', async () => {
        const expectedContractid = keccak256(toUtf8Bytes('token-manager'));
        const contractId = await tokenManagerTest.contractId();
        expect(contractId).to.eq(expectedContractid);
    });

    it('Should revert on setup if not called by the proxy', async () => {
        const params = '0x';
        await expectRevert((gasOptions) => tokenManagerTest.setup(params, gasOptions), tokenManagerTest, 'NotProxy');
    });

    it('Should revert on transmitInterchainTransfer if not called by the token', async () => {
        const sender = owner.address;
        const destinationChain = 'Dest Chain';
        const destinationAddress = toUtf8Bytes(user.address);
        const amount = 10;
        const metadata = '0x00000000';

        await expectRevert(
            (gasOptions) =>
                tokenManagerTest.transmitInterchainTransfer(sender, destinationChain, destinationAddress, amount, metadata, gasOptions),
            tokenManagerTest,
            'NotToken',
            [sender],
        );
    });

    it('Should revert on giveToken if not called by the service', async () => {
        const destinationAddress = user.address;
        const amount = 10;

        await expectRevert(
            (gasOptions) => tokenManagerTest.giveToken(destinationAddress, amount, gasOptions),
            tokenManagerTest,
            'NotService',
            [owner.address],
        );
    });

    it('Should revert on takeToken if not called by the service', async () => {
        const sourceAddress = user.address;
        const amount = 10;

        await expectRevert((gasOptions) => tokenManagerTest.takeToken(sourceAddress, amount, gasOptions), tokenManagerTest, 'NotService', [
            owner.address,
        ]);
    });

    it('Should revert on setFlowLimit if not called by the operator', async () => {
        const flowLimit = 100;

        await expectRevert((gasOptions) => tokenManagerTest.setFlowLimit(flowLimit, gasOptions), tokenManagerTest, 'MissingRole', [
            owner.address,
            FLOW_LIMITER_ROLE,
        ]);
    });

    it('Should revert on addFlowLimiter if flow limiter address is invalid', async () => {
        await tokenManagerTest.addOperator(owner.address).then((tx) => tx.wait());

        await expectRevert((gasOptions) => tokenManagerTest.addFlowLimiter(AddressZero, gasOptions), tokenManagerTest, 'ZeroAddress', []);
    });

    it('Should revert on removeFlowLimiter if flow limiter address is invalid', async () => {
        await tokenManagerTest.addOperator(owner.address).then((tx) => tx.wait());

        await expectRevert(
            (gasOptions) => tokenManagerTest.removeFlowLimiter(AddressZero, gasOptions),
            tokenManagerTest,
            'ZeroAddress',
            [],
        );
    });

    it('Should return the correct parameters for lock/unlock token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerLockUnlock.params(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should return the correct parameters for mint/burn token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerMintBurn.params(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should return the correct parameters for fee on transfer token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await tokenManagerLockUnlockFeeOnTransfer.params(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });
});
