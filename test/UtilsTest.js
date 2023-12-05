'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    Wallet,
    getContractAt,
    constants: { AddressZero },
} = ethers;
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = chai;
const { getRandomBytes32, expectRevert, isHardhat, waitFor } = require('./utils');
const { deployContract } = require('../scripts/deploy');

let ownerWallet, otherWallet;

before(async () => {
    const wallets = await ethers.getSigners();
    ownerWallet = wallets[0];
    otherWallet = wallets[1];
});

describe('Operatable', () => {
    let test;
    let operatorRole;

    before(async () => {
        test = await deployContract(ownerWallet, 'TestOperatable', [ownerWallet.address]);
        operatorRole = await test.operatorRole();
    });

    it('Should be able to run the onlyOperatorable function as the operator', async () => {
        await (await test.testOperatorable()).wait();

        expect(await test.nonce()).to.equal(1);
    });

    it('Should not be able to run the onlyOperatorable function as not the operator', async () => {
        await expectRevert((gasOptions) => test.connect(otherWallet).testOperatorable(gasOptions), test, 'MissingRole', [
            otherWallet.address,
            operatorRole,
        ]);
    });

    it('Should return true on isOperator if an address is an operator', async () => {
        expect(await test.isOperator(ownerWallet.address)).to.be.true;
    });

    it('Should be able to change the operator only as the operator', async () => {
        expect(await test.hasRole(ownerWallet.address, operatorRole)).to.be.true;

        await expect(test.transferOperatorship(otherWallet.address))
            .to.emit(test, 'RolesRemoved')
            .withArgs(ownerWallet.address, 1 << operatorRole)
            .to.emit(test, 'RolesAdded')
            .withArgs(otherWallet.address, 1 << operatorRole);

        expect(await test.hasRole(otherWallet.address, operatorRole)).to.be.true;

        await expectRevert((gasOptions) => test.transferOperatorship(otherWallet.address, gasOptions), test, 'MissingRole', [
            ownerWallet.address,
            operatorRole,
        ]);
    });

    it('Should be able to propose operator only as the operator', async () => {
        expect(await test.hasRole(otherWallet.address, operatorRole)).to.be.true;

        await expectRevert((gasOptions) => test.proposeOperatorship(ownerWallet.address, gasOptions), test, 'MissingRole', [
            ownerWallet.address,
            operatorRole,
        ]);

        await expect(test.connect(otherWallet).proposeOperatorship(ownerWallet.address))
            .to.emit(test, 'RolesProposed')
            .withArgs(otherWallet.address, ownerWallet.address, 1 << operatorRole);
    });

    it('Should be able to accept operatorship only as proposed operator', async () => {
        expect(await test.hasRole(otherWallet.address, operatorRole)).to.be.true;

        await expectRevert(
            (gasOptions) => test.connect(otherWallet).acceptOperatorship(otherWallet.address, gasOptions),
            test,
            'InvalidProposedRoles',
            [otherWallet.address, otherWallet.address, 1 << operatorRole],
        );

        await expect(test.connect(ownerWallet).acceptOperatorship(otherWallet.address))
            .to.emit(test, 'RolesRemoved')
            .withArgs(otherWallet.address, 1 << operatorRole)
            .to.emit(test, 'RolesAdded')
            .withArgs(ownerWallet.address, 1 << operatorRole);
    });
});

describe('Distributable', () => {
    let test;
    let minterRole;

    before(async () => {
        test = await deployContract(ownerWallet, 'TestDistributable', [ownerWallet.address]);
        minterRole = await test.minterRole();
    });

    it('Should be able to run the onlyMinter function as the minter', async () => {
        await (await test.testDistributable()).wait();

        expect(await test.nonce()).to.equal(1);
    });

    it('Should not be able to run the onlyMinter function as not the minter', async () => {
        await expectRevert((gasOptions) => test.connect(otherWallet).testDistributable(gasOptions), test, 'MissingRole', [
            otherWallet.address,
            minterRole,
        ]);
    });

    it('Should be able to change the minter only as the minter', async () => {
        expect(await test.hasRole(ownerWallet.address, minterRole)).to.be.true;

        await expect(test.transferMinterRole(otherWallet.address))
            .to.emit(test, 'RolesRemoved')
            .withArgs(ownerWallet.address, 1 << minterRole)
            .to.emit(test, 'RolesAdded')
            .withArgs(otherWallet.address, 1 << minterRole);

        expect(await test.hasRole(otherWallet.address, minterRole)).to.be.true;

        await expectRevert((gasOptions) => test.transferMinterRole(otherWallet.address, gasOptions), test, 'MissingRole', [
            ownerWallet.address,
            minterRole,
        ]);
    });

    it('Should be able to propose a new minter only as minter', async () => {
        expect(await test.hasRole(otherWallet.address, minterRole)).to.be.true;

        await expectRevert(
            (gasOptions) => test.connect(ownerWallet).proposeMinterRole(ownerWallet.address, gasOptions),
            test,
            'MissingRole',
            [ownerWallet.address, minterRole],
        );

        await expect(test.connect(otherWallet).proposeMinterRole(ownerWallet.address))
            .to.emit(test, 'RolesProposed')
            .withArgs(otherWallet.address, ownerWallet.address, 1 << minterRole);
    });

    it('Should be able to accept minterRole only as the proposed minter', async () => {
        expect(await test.hasRole(otherWallet.address, minterRole)).to.be.true;

        await expectRevert(
            (gasOptions) => test.connect(otherWallet).acceptMinterRole(otherWallet.address, gasOptions),
            test,
            'InvalidProposedRoles',
        );

        await expect(test.connect(ownerWallet).acceptMinterRole(otherWallet.address))
            .to.emit(test, 'RolesRemoved')
            .withArgs(otherWallet.address, 1 << minterRole)
            .to.emit(test, 'RolesAdded')
            .withArgs(ownerWallet.address, 1 << minterRole);
    });
});

describe('FlowLimit', async () => {
    let test;
    let tokenId;
    const flowLimit = isHardhat ? 5 : 2;

    before(async () => {
        test = isHardhat
            ? await deployContract(ownerWallet, 'TestFlowLimit')
            : await deployContract(ownerWallet, 'TestFlowLimitLiveNetwork');
        tokenId = await test.TOKEN_ID();
    });

    async function nextEpoch() {
        const epoch = isHardhat ? 6 * 3600 : 60;

        if (isHardhat) {
            const latest = Number(await time.latest());
            const next = (Math.floor(latest / epoch) + 1) * epoch;

            await time.increaseTo(next);
        } else {
            await waitFor(epoch);
        }
    }

    it('Should calculate hardcoded constants correctly', async () => {
        await expect(deployContract(ownerWallet, `TestFlowLimit`, [])).to.not.be.reverted;
    });

    it('Should be able to set the flow limit', async () => {
        await expect(test.setFlowLimit(flowLimit)).to.emit(test, 'FlowLimitSet').withArgs(tokenId, ownerWallet.address, flowLimit);

        expect(await test.flowLimit()).to.equal(flowLimit);
    });

    it('Should test flow in', async () => {
        await nextEpoch();

        for (let i = 0; i < flowLimit; i++) {
            await (await test.addFlowIn(1)).wait();
            expect(await test.flowInAmount()).to.equal(i + 1);
        }

        await expectRevert((gasOptions) => test.addFlowIn(1, gasOptions), test, 'FlowLimitExceeded', [
            flowLimit,
            flowLimit + 1,
            test.address,
        ]);

        await nextEpoch();

        expect(await test.flowInAmount()).to.equal(0);

        await (await test.addFlowIn(flowLimit)).wait();
    });

    it('Should test flow out', async () => {
        await nextEpoch();

        for (let i = 0; i < flowLimit; i++) {
            await (await test.addFlowOut(1)).wait();
            expect(await test.flowOutAmount()).to.equal(i + 1);
        }

        await expectRevert((gasOptions) => test.addFlowOut(1, gasOptions), test, 'FlowLimitExceeded', [
            flowLimit,
            flowLimit + 1,
            test.address,
        ]);

        await nextEpoch();

        expect(await test.flowOutAmount()).to.equal(0);

        await (await test.addFlowOut(flowLimit)).wait();
    });

    it('Should revert if single flow amount exceeds the flow limit', async () => {
        const excessiveFlowAmount = flowLimit + 1;
        await test.setFlowLimit(flowLimit).then((tx) => tx.wait());

        await test.addFlowIn(flowLimit - 1).then((tx) => tx.wait());

        await expectRevert((gasOptions) => test.addFlowIn(excessiveFlowAmount, gasOptions), test, 'FlowLimitExceeded', [
            flowLimit,
            excessiveFlowAmount,
            test.address,
        ]);
    });
});

describe('InterchainTokenDeployer', () => {
    let interchainToken, interchainTokenDeployer;
    const service = new Wallet(getRandomBytes32()).address;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const MINTER_ROLE = 0;

    before(async () => {
        interchainToken = await deployContract(ownerWallet, 'InterchainToken', [service]);
        interchainTokenDeployer = await deployContract(ownerWallet, 'InterchainTokenDeployer', [interchainToken.address]);
    });

    it('Should revert on deployment with invalid implementation address', async () => {
        await expectRevert(
            (gasOptions) => deployContract(ownerWallet, 'InterchainTokenDeployer', [AddressZero, gasOptions]),
            interchainTokenDeployer,
            'AddressZero',
        );
    });

    it('Should deploy a mint burn token only once', async () => {
        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();
        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        const token = await getContractAt('InterchainToken', tokenAddress, ownerWallet);

        await expect(interchainTokenDeployer.deployInterchainToken(salt, tokenId, ownerWallet.address, name, symbol, decimals))
            .to.emit(token, 'RolesAdded')
            .withArgs(service, 1 << MINTER_ROLE)
            .and.to.emit(token, 'RolesAdded')
            .withArgs(ownerWallet.address, 1 << MINTER_ROLE);

        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.hasRole(service, MINTER_ROLE)).to.be.true;
        expect(await token.hasRole(ownerWallet.address, MINTER_ROLE)).to.be.true;
        expect(await token.interchainTokenId()).to.equal(tokenId);
        expect(await token.interchainTokenService()).to.equal(service);

        await expectRevert(
            (gasOptions) =>
                interchainTokenDeployer.deployInterchainToken(salt, tokenId, ownerWallet.address, name, symbol, decimals, gasOptions),
            interchainTokenDeployer,
            'AlreadyDeployed',
        );
    });
});
