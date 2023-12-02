'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    utils: { keccak256, toUtf8Bytes, defaultAbiCoder },
    constants: { AddressZero },
} = ethers;
const { expect } = chai;
const { expectRevert, getEVMVersion } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('Token Manager', () => {
    const FLOW_LIMITER_ROLE = 2;
    let owner, token, service;
    let TestTokenManager;

    before(async () => {
        [owner, token, service] = await ethers.getSigners();

        TestTokenManager = await deployContract(owner, `TestTokenManager`, [service.address]);
    });

    it('Should revert on token manager deployment with invalid service address', async () => {
        await expectRevert(
            (gasOptions) => deployContract(owner, `TestTokenManager`, [AddressZero, gasOptions]),
            TestTokenManager,
            'TokenLinkerZeroAddress',
        );
    });

    it('Should return the correct contract id', async () => {
        const expectedContractid = keccak256(toUtf8Bytes('token-manager'));
        const contractId = await TestTokenManager.contractId();
        expect(contractId).to.eq(expectedContractid);
    });

    it('Should revert on setup if not called by the proxy', async () => {
        const params = '0x';
        await expectRevert((gasOptions) => TestTokenManager.setup(params, gasOptions), TestTokenManager, 'NotProxy');
    });

    it('Should revert on setFlowLimit if not called by the operator', async () => {
        const flowLimit = 100;

        await expectRevert((gasOptions) => TestTokenManager.setFlowLimit(flowLimit, gasOptions), TestTokenManager, 'MissingRole', [
            owner.address,
            FLOW_LIMITER_ROLE,
        ]);
    });

    it('Should revert on addFlowLimiter if flow limiter address is invalid', async () => {
        await TestTokenManager.addOperator(owner.address).then((tx) => tx.wait());

        await expectRevert((gasOptions) => TestTokenManager.addFlowLimiter(AddressZero, gasOptions), TestTokenManager, 'ZeroAddress', []);
    });

    it('Should revert on removeFlowLimiter if flow limiter address is invalid', async () => {
        await TestTokenManager.addOperator(owner.address).then((tx) => tx.wait());

        await expectRevert(
            (gasOptions) => TestTokenManager.removeFlowLimiter(AddressZero, gasOptions),
            TestTokenManager,
            'ZeroAddress',
            [],
        );
    });

    it('Should return the correct parameters for a token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await TestTokenManager.params(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    it('Should preserve the same proxy bytecode for each EVM [ @skip-on-coverage ]', async () => {
        const proxyFactory = await ethers.getContractFactory('TokenManagerProxy', owner);
        const proxyBytecode = proxyFactory.bytecode;
        const proxyBytecodeHash = keccak256(proxyBytecode);

        const expected = {
            istanbul: '0xce3ee5c04c84351d193a6e5dc52e34702039a6083437b077367bac26da57103c',
            berlin: '0xea7ab1f8727ce63dd60f1b7c6770723259b7ac2ce69a74046509e2a65cd4b899',
            london: '0x97da1989bb59bf727d23961f163900ce0dcab3dafa2b3fa0aec39f09c5bd233e',
        }[getEVMVersion()];

        expect(proxyBytecodeHash).to.be.equal(expected);
    });
});
