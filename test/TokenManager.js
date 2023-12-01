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
            istanbul: '0x6b736a5ec65994238466070da91520144aaa3b41ecdcda7cfa4e7b6cd2296347',
            berlin: '0xcbd407743ce6492f90dc2542f2ad71ca6c99d21fd29cc9a8fdf6ff54bb28131f',
            london: '0x028f986ea9320071af6747d2dad9e0870c28e8bd19542168f5e4855566e38376',
        }[getEVMVersion()];

        expect(proxyBytecodeHash).to.be.equal(expected);
    });
});
