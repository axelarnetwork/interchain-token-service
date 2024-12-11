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
    let owner, other;
    let TestTokenManager;

    before(async () => {
        [owner, other] = await ethers.getSigners();

        TestTokenManager = await deployContract(owner, `TestTokenManager`, [other.address]);
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

    it('Should revert on mintToken when calling directly', async () => {
        await expectRevert(
            (gasOptions) => TestTokenManager.mintToken(other.address, owner.address, 1234, gasOptions),
            TestTokenManager,
            'NotService',
            [owner.address],
        );
    });

    it('Should revert on burnToken when calling directly', async () => {
        await expectRevert(
            (gasOptions) => TestTokenManager.burnToken(other.address, owner.address, 1234, gasOptions),
            TestTokenManager,
            'NotService',
            [owner.address],
        );
    });

    it('Should return the correct parameters for a token manager', async () => {
        const expectedParams = defaultAbiCoder.encode(['bytes', 'address'], [toUtf8Bytes(owner.address), other.address]);
        const params = await TestTokenManager.params(toUtf8Bytes(owner.address), other.address);
        expect(expectedParams).to.eq(params);
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same proxy bytecode for each EVM', async () => {
            const proxyFactory = await ethers.getContractFactory('TokenManagerProxy', owner);
            const proxyBytecode = proxyFactory.bytecode;
            const proxyBytecodeHash = keccak256(proxyBytecode);

            const expected = {
                london: '0x3b336208cc75ca67bdd39bdeed72871ce795e6e9cd28e20f811599ea51973ebf',
            }[getEVMVersion()];

            expect(proxyBytecodeHash).to.be.equal(expected);
        });
    });
});
