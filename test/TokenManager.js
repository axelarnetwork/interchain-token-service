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

    it('Should revert on addFlowIn when calling directly', async () => {
        await expectRevert((gasOptions) => TestTokenManager.addFlowIn(0, gasOptions), TestTokenManager, 'NotService', [owner.address]);
    });

    it('Should revert on addFlowOut when calling directly', async () => {
        await expectRevert((gasOptions) => TestTokenManager.addFlowOut(0, gasOptions), TestTokenManager, 'NotService', [owner.address]);
    });

    it('Should revert on approveService when calling directly', async () => {
        await expectRevert((gasOptions) => TestTokenManager.approveService(gasOptions), TestTokenManager, 'NotService', [owner.address]);
    });

    it('Should return the correct parameters for a token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), token.address]);
        const params = await TestTokenManager.params(toUtf8Bytes(owner.address), token.address);
        expect(expectedParams).to.eq(params);
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same proxy bytecode for each EVM', async () => {
            const proxyFactory = await ethers.getContractFactory('TokenManagerProxy', owner);
            const proxyBytecode = proxyFactory.bytecode;
            const proxyBytecodeHash = keccak256(proxyBytecode);

            const expected = {
                istanbul: '0x8e833c9efc444489f636e5582be33991c73273049065a071e414b3fc6e64bb54',
                berlin: '0x6e1fe42f41fb15015c4fc5b702747255296568a52b019b8f061c000921433aa3',
                london: '0x6ff5905df915a3661814814739766a16d87576480c270fda42c04c25955716ad',
            }[getEVMVersion()];

            expect(proxyBytecodeHash).to.be.equal(expected);
        });
    });
});
