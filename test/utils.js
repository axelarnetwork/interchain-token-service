'use strict';

require('dotenv').config();
const chai = require('chai');
const { ethers } = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { Wallet, Contract } = ethers;
const { AddressZero } = ethers.constants;
const { defaultAbiCoder } = ethers.utils;
const { expect } = chai;
const { getRandomBytes32 } = require('../scripts/utils');
const { deployContract } = require('../scripts/deploy');

const ImplemenationTest = require('../artifacts/contracts/test/utils/ImplementationTest.sol/ImplementationTest.json');
const StandardizedToken = require('../artifacts/contracts/token-implementations/StandardizedToken.sol/StandardizedToken.json');
const StandardizedTokenProxy = require('../artifacts/contracts/proxies/StandardizedTokenProxy.sol/StandardizedTokenProxy.json');

let ownerWallet, otherWallet;
before(async () => {
    const wallets = await ethers.getSigners();
    ownerWallet = wallets[0];
    otherWallet = wallets[1];
});

describe('Operatable', () => {
    let test;
    before(async () => {
        test = await deployContract(ownerWallet, 'OperatorableTest', [ownerWallet.address]);
    });

    it('Should be able to run the onlyOperatorable function as the operator', async () => {
        await (await test.testOperatorable()).wait();
        expect(await test.nonce()).to.equal(1);
    });

    it('Should not be able to run the onlyOperatorable function as not the operator', async () => {
        await expect(test.connect(otherWallet).testOperatorable()).to.be.revertedWithCustomError(test, 'NotOperator');
    });

    it('Should be able to change the operator only as the operator', async () => {
        expect(await test.operator()).to.equal(ownerWallet.address);
        await expect(test.transferOperatorship(otherWallet.address)).to.emit(test, 'OperatorshipTransferred').withArgs(otherWallet.address);
        expect(await test.operator()).to.equal(otherWallet.address);
        await expect(test.transferOperatorship(otherWallet.address)).to.be.revertedWithCustomError(test, 'NotOperator');
    });

    it('Should be able to propose operator only as the operator', async () => {
        expect(await test.operator()).to.equal(otherWallet.address);
        await expect(test.proposeOperatorship(ownerWallet.address)).to.be.revertedWithCustomError(test, 'NotOperator');
        await expect(test.connect(otherWallet).proposeOperatorship(ownerWallet.address))
            .to.emit(test, 'OperatorChangeProposed')
            .withArgs(ownerWallet.address);
    });

    it('Should be able to accept operatorship only as proposed operator', async () => {
        expect(await test.operator()).to.equal(otherWallet.address);
        await expect(test.connect(otherWallet).acceptOperatorship()).to.be.revertedWithCustomError(test, 'NotProposedOperator');
        await expect(test.acceptOperatorship()).to.emit(test, 'OperatorshipTransferred').withArgs(ownerWallet.address);
    });
});

describe('Distributable', () => {
    let test;
    before(async () => {
        test = await deployContract(ownerWallet, 'DistributableTest', [ownerWallet.address]);
    });

    it('Should be able to run the onlyDistributor function as the distributor', async () => {
        await (await test.testDistributable()).wait();
        expect(await test.nonce()).to.equal(1);
    });

    it('Should not be able to run the onlyDistributor function as not the distributor', async () => {
        await expect(test.connect(otherWallet).testDistributable()).to.be.revertedWithCustomError(test, 'NotDistributor');
    });

    it('Should be able to change the distributor only as the distributor', async () => {
        expect(await test.distributor()).to.equal(ownerWallet.address);
        await expect(test.transferDistributorship(otherWallet.address))
            .to.emit(test, 'DistributorshipTransferred')
            .withArgs(otherWallet.address);
        expect(await test.distributor()).to.equal(otherWallet.address);
        await expect(test.transferDistributorship(otherWallet.address)).to.be.revertedWithCustomError(test, 'NotDistributor');
    });

    it('Should be able to propose a new distributor only as distributor', async () => {
        expect(await test.distributor()).to.equal(otherWallet.address);
        await expect(test.connect(ownerWallet).proposeDistributorship(ownerWallet.address)).to.be.revertedWithCustomError(
            test,
            'NotDistributor',
        );
        await expect(test.connect(otherWallet).proposeDistributorship(ownerWallet.address))
            .to.emit(test, 'DistributorshipTransferStarted')
            .withArgs(ownerWallet.address);
    });

    it('Should be able to accept distributorship only as the proposed distributor', async () => {
        expect(await test.distributor()).to.equal(otherWallet.address);
        await expect(test.connect(otherWallet).acceptDistributorship()).to.be.revertedWithCustomError(test, 'NotProposedDistributor');
        await expect(test.connect(ownerWallet).acceptDistributorship())
            .to.emit(test, 'DistributorshipTransferred')
            .withArgs(ownerWallet.address);
    });
});

describe('ExpressCallHandler', () => {
    let handler;
    const expressCaller = new Wallet(getRandomBytes32()).address;
    const payload = '0x5678';

    before(async () => {
        handler = await deployContract(ownerWallet, 'ExpressCallHandlerTest');
    });

    it('Should be able to set an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.setExpressReceiveToken(payload, commandId, expressCaller))
            .to.emit(handler, 'ExpressReceive')
            .withArgs(payload, commandId, expressCaller);
        expect(await handler.getExpressReceiveToken(payload, commandId)).to.equal(expressCaller);
    });

    it('Should not be able to set an express receive token if it is already set', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.setExpressReceiveToken(payload, commandId, expressCaller))
            .to.emit(handler, 'ExpressReceive')
            .withArgs(payload, commandId, expressCaller);
        expect(await handler.getExpressReceiveToken(payload, commandId)).to.equal(expressCaller);

        const newExpressCaller = new Wallet(getRandomBytes32()).address;
        await expect(handler.setExpressReceiveToken(payload, commandId, newExpressCaller)).to.be.revertedWithCustomError(
            handler,
            'AlreadyExpressCalled',
        );
    });

    it('Should properly pop an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.popExpressReceiveToken(payload, commandId)).to.not.emit(handler, 'ExpressExecutionFulfilled');
        expect(await handler.lastPoppedExpressCaller()).to.equal(AddressZero);

        await (await handler.setExpressReceiveToken(payload, commandId, expressCaller)).wait();

        await expect(handler.popExpressReceiveToken(payload, commandId))
            .to.emit(handler, 'ExpressExecutionFulfilled')
            .withArgs(payload, commandId, expressCaller);
        expect(await handler.lastPoppedExpressCaller()).to.equal(expressCaller);
    });
});

describe('FlowLimit', async () => {
    let test;
    const flowLimit = 5;
    before(async () => {
        test = await deployContract(ownerWallet, 'FlowLimitTest');
    });

    async function nextEpoch() {
        const latest = Number(await time.latest());
        const epoch = 6 * 3600;
        const next = (Math.floor(latest / epoch) + 1) * epoch;
        await time.increaseTo(next);
    }

    it('Should be able to set the flow limit', async () => {
        await expect(test.setFlowLimit(flowLimit)).to.emit(test, 'FlowLimitSet').withArgs(flowLimit);
        expect(await test.getFlowLimit()).to.equal(flowLimit);
    });

    it('Should test flow in', async () => {
        await nextEpoch();

        for (let i = 0; i < flowLimit; i++) {
            await (await test.addFlowIn(1)).wait();
            expect(await test.getFlowInAmount()).to.equal(i + 1);
        }

        await expect(test.addFlowIn(1)).to.be.revertedWithCustomError(test, 'FlowLimitExceeded');

        await nextEpoch();

        expect(await test.getFlowInAmount()).to.equal(0);
        await (await test.addFlowIn(flowLimit)).wait();
    });

    it('Should test flow out', async () => {
        await nextEpoch();

        for (let i = 0; i < flowLimit; i++) {
            await (await test.addFlowOut(1)).wait();
            expect(await test.getFlowOutAmount()).to.equal(i + 1);
        }

        await expect(test.addFlowOut(1)).to.be.revertedWithCustomError(test, 'FlowLimitExceeded');

        await nextEpoch();

        expect(await test.getFlowOutAmount()).to.equal(0);
        await (await test.addFlowOut(flowLimit)).wait();
    });
});

describe('Implementation', () => {
    let implementation, proxy;

    before(async () => {
        implementation = await deployContract(ownerWallet, 'ImplementationTest');
        proxy = await deployContract(ownerWallet, 'NakedProxy', [implementation.address]);
        proxy = new Contract(proxy.address, ImplemenationTest.abi, ownerWallet);
    });

    it('Should test the implemenation contract', async () => {
        const val = 123;
        const params = defaultAbiCoder.encode(['uint256'], [val]);
        await (await proxy.setup(params)).wait();
        expect(await proxy.val()).to.equal(val);

        await expect(implementation.setup(params)).to.be.revertedWithCustomError(implementation, 'NotProxy');
    });
});

describe('Mutlicall', () => {
    let test;
    let function1Data;
    let function2Data;
    let function3Data;

    before(async () => {
        test = await deployContract(ownerWallet, 'MulticallTest');
        function1Data = (await test.populateTransaction.function1()).data;
        function2Data = (await test.populateTransaction.function2()).data;
        function3Data = (await test.populateTransaction.function3()).data;
    });

    it('Shoult test the multicall', async () => {
        const nonce = Number(await test.nonce());
        await expect(test.multicall([function1Data, function2Data, function2Data, function1Data]))
            .to.emit(test, 'Function1Called')
            .withArgs(nonce + 0)
            .and.to.emit(test, 'Function2Called')
            .withArgs(nonce + 1)
            .and.to.emit(test, 'Function2Called')
            .withArgs(nonce + 2)
            .and.to.emit(test, 'Function1Called')
            .withArgs(nonce + 3);
    });

    it('Shoult test the multicall returns', async () => {
        const nonce = Number(await test.nonce());
        await expect(test.multicallTest([function2Data, function1Data, function2Data, function2Data]))
            .to.emit(test, 'Function2Called')
            .withArgs(nonce + 0)
            .and.to.emit(test, 'Function1Called')
            .withArgs(nonce + 1)
            .and.to.emit(test, 'Function2Called')
            .withArgs(nonce + 2)
            .and.to.emit(test, 'Function2Called')
            .withArgs(nonce + 3);
        const lastReturns = await test.getLastMulticallReturns();

        for (let i = 0; i < lastReturns.length; i++) {
            const val = Number(defaultAbiCoder.decode(['uint256'], lastReturns[i]));
            expect(val).to.equal(nonce + i);
        }
    });

    it('Shoult revert if any of the calls fail', async () => {
        const nonce = Number(await test.nonce());
        await expect(test.multicall([function1Data, function2Data, function3Data, function1Data]))
            .to.emit(test, 'Function1Called')
            .withArgs(nonce + 0)
            .and.to.emit(test, 'Function2Called')
            .withArgs(nonce + 1).to.be.reverted;
    });
});

describe('Pausable', () => {
    let test;
    before(async () => {
        test = await deployContract(ownerWallet, 'PausableTest');
    });

    it('Should be able to set paused to true or false', async () => {
        await expect(test.setPaused(true)).to.emit(test, 'PausedSet').withArgs(true);
        expect(await test.isPaused()).to.equal(true);
        await expect(test.setPaused(false)).to.emit(test, 'PausedSet').withArgs(false);
        expect(await test.isPaused()).to.equal(false);
    });

    it('Should be able to execute notPaused functions only when not paused', async () => {
        await expect(test.setPaused(false)).to.emit(test, 'PausedSet').withArgs(false);
        await expect(test.testPaused()).to.emit(test, 'TestEvent');

        await expect(test.setPaused(true)).to.emit(test, 'PausedSet').withArgs(true);
        await expect(test.testPaused()).to.be.revertedWithCustomError(test, 'Paused');
    });
});

describe('StandardizedTokenDeployer', () => {
    let standardizedToken, standardizedTokenDeployer;
    const tokenManager = new Wallet(getRandomBytes32()).address;
    const mintTo = new Wallet(getRandomBytes32()).address;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    before(async () => {
        standardizedToken = await deployContract(ownerWallet, 'StandardizedToken');
        standardizedTokenDeployer = await deployContract(ownerWallet, 'StandardizedTokenDeployer', [standardizedToken.address]);
    });

    it('Should revert on deployment with invalid implementation address', async () => {
        await expect(deployContract(ownerWallet, 'StandardizedTokenDeployer', [AddressZero])).to.be.revertedWithCustomError(
            standardizedTokenDeployer,
            'AddressZero',
        );
    });

    it('Should deploy a mint burn token only once', async () => {
        const salt = getRandomBytes32();

        const tokenAddress = await standardizedTokenDeployer.deployedAddress(salt);

        const token = new Contract(tokenAddress, StandardizedToken.abi, ownerWallet);
        const tokenProxy = new Contract(tokenAddress, StandardizedTokenProxy.abi, ownerWallet);

        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, tokenManager, name, symbol, decimals, mintAmount, mintTo),
        )
            .to.emit(token, 'Transfer')
            .withArgs(AddressZero, mintTo, mintAmount)
            .and.to.emit(token, 'DistributorshipTransferred')
            .withArgs(tokenManager);

        expect(await tokenProxy.implementation()).to.equal(standardizedToken.address);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.balanceOf(mintTo)).to.equal(mintAmount);
        expect(await token.distributor()).to.equal(tokenManager);
        expect(await token.tokenManager()).to.equal(tokenManager);
        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, tokenManager, name, symbol, decimals, mintAmount, mintTo),
        ).to.be.revertedWithCustomError(standardizedTokenDeployer, 'AlreadyDeployed');
    });
});
