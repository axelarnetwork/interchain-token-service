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
        await expect(test.transferOperatorship(otherWallet.address)).to.emit(test, 'OperatorChanged').withArgs(otherWallet.address);
        expect(await test.operator()).to.equal(otherWallet.address);
        await expect(test.transferOperatorship(otherWallet.address)).to.be.revertedWithCustomError(test, 'NotOperator');
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
        await expect(test.transferDistributorship(otherWallet.address)).to.emit(test, 'DistributorChanged').withArgs(otherWallet.address);
        expect(await test.distributor()).to.equal(otherWallet.address);
        await expect(test.transferDistributorship(otherWallet.address)).to.be.revertedWithCustomError(test, 'NotDistributor');
    });
});

describe('ExpressCallHandler', () => {
    let handler;
    const tokenId = getRandomBytes32();
    const destinationAddress = new Wallet(getRandomBytes32()).address;
    const amount = 123;
    const expressCaller = new Wallet(getRandomBytes32()).address;
    const sourceChain = 'sourceChain';
    const sourceAddress = '0x1234';
    const data = '0x5678';

    before(async () => {
        handler = await deployContract(ownerWallet, 'ExpressCallHandlerTest');
    });

    it('Should be able to set an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, expressCaller))
            .to.emit(handler, 'ExpressReceive')
            .withArgs(tokenId, destinationAddress, amount, commandId, expressCaller);
        expect(await handler.getExpressReceiveToken(tokenId, destinationAddress, amount, commandId)).to.equal(expressCaller);
    });

    it('Should not be able to set an express receive token if it is already set', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, expressCaller))
            .to.emit(handler, 'ExpressReceive')
            .withArgs(tokenId, destinationAddress, amount, commandId, expressCaller);
        expect(await handler.getExpressReceiveToken(tokenId, destinationAddress, amount, commandId)).to.equal(expressCaller);

        const newExpressCaller = new Wallet(getRandomBytes32()).address;
        await expect(
            handler.setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, newExpressCaller),
        ).to.be.revertedWithCustomError(handler, 'AlreadyExpressCalled');
    });

    it('Should be able to set an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(
            handler.setExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                expressCaller,
            ),
        )
            .to.emit(handler, 'ExpressReceiveWithData')
            .withArgs(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
        expect(
            await handler.getExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId),
        ).to.equal(expressCaller);
    });

    it('Should be able to set an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(
            handler.setExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                expressCaller,
            ),
        )
            .to.emit(handler, 'ExpressReceiveWithData')
            .withArgs(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
        expect(
            await handler.getExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId),
        ).to.equal(expressCaller);

        const newExpressCaller = new Wallet(getRandomBytes32()).address;
        await expect(
            handler.setExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                newExpressCaller,
            ),
        ).to.be.revertedWithCustomError(handler, 'AlreadyExpressCalled');
    });

    it('Should properly pop an express receive token', async () => {
        const commandId = getRandomBytes32();
        await expect(handler.popExpressReceiveToken(tokenId, destinationAddress, amount, commandId)).to.not.emit(
            handler,
            'ExpressExecutionFulfilled',
        );
        expect(await handler.lastPoppedExpressCaller()).to.equal(AddressZero);

        await (await handler.setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, expressCaller)).wait();

        await expect(handler.popExpressReceiveToken(tokenId, destinationAddress, amount, commandId))
            .to.emit(handler, 'ExpressExecutionFulfilled')
            .withArgs(tokenId, destinationAddress, amount, commandId, expressCaller);
        expect(await handler.lastPoppedExpressCaller()).to.equal(expressCaller);
    });

    it('Should properly pop an express receive token with data', async () => {
        const commandId = getRandomBytes32();
        await expect(
            handler.popExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId),
        ).to.not.emit(handler, 'ExpressExecutionWithDataFulfilled');
        expect(await handler.lastPoppedExpressCaller()).to.equal(AddressZero);

        await (
            await handler.setExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                expressCaller,
            )
        ).wait();

        await expect(
            handler.popExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId),
        )
            .to.emit(handler, 'ExpressExecutionWithDataFulfilled')
            .withArgs(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
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

    before(async () => {
        test = await deployContract(ownerWallet, 'MulticallTest');
        function1Data = (await test.populateTransaction.function1()).data;
        function2Data = (await test.populateTransaction.function2()).data;
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
    let create3Deployer, standardizedTokenLockUnlock, standardizedTokenDeployer, standardizedTokenMintBurn;
    const tokenManager = new Wallet(getRandomBytes32()).address;
    const distributor = new Wallet(getRandomBytes32()).address;
    const mintTo = new Wallet(getRandomBytes32()).address;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    before(async () => {
        create3Deployer = await deployContract(ownerWallet, 'Create3Deployer');
        standardizedTokenLockUnlock = await deployContract(ownerWallet, 'StandardizedTokenLockUnlock');
        standardizedTokenMintBurn = await deployContract(ownerWallet, 'StandardizedTokenMintBurn');
        standardizedTokenDeployer = await deployContract(ownerWallet, 'StandardizedTokenDeployer', [
            create3Deployer.address,
            standardizedTokenLockUnlock.address,
            standardizedTokenMintBurn.address,
        ]);
    });

    it('Should deploy a lock unlock token only once', async () => {
        const salt = getRandomBytes32();

        const tokenAddress = await create3Deployer.deployedAddress(standardizedTokenDeployer.address, salt);

        const token = new Contract(tokenAddress, StandardizedToken.abi, ownerWallet);
        const tokenProxy = new Contract(tokenAddress, StandardizedTokenProxy.abi, ownerWallet);

        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, distributor, name, symbol, decimals, mintAmount, mintTo),
        )
            .to.emit(token, 'Transfer')
            .withArgs(AddressZero, mintTo, mintAmount)
            .and.to.emit(token, 'DistributorChanged')
            .withArgs(distributor);

        expect(await tokenProxy.implementation()).to.equal(standardizedTokenLockUnlock.address);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.balanceOf(mintTo)).to.equal(mintAmount);
        expect(await token.distributor()).to.equal(distributor);
        expect(await token.tokenManager()).to.equal(tokenManager);
        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, distributor, name, symbol, decimals, mintAmount, mintTo),
        ).to.be.revertedWithCustomError(create3Deployer, 'AlreadyDeployed');
    });

    it('Should deploy a mint burn token only once', async () => {
        const salt = getRandomBytes32();

        const tokenAddress = await create3Deployer.deployedAddress(standardizedTokenDeployer.address, salt);

        const token = new Contract(tokenAddress, StandardizedToken.abi, ownerWallet);
        const tokenProxy = new Contract(tokenAddress, StandardizedTokenProxy.abi, ownerWallet);

        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, tokenManager, name, symbol, decimals, mintAmount, mintTo),
        )
            .to.emit(token, 'Transfer')
            .withArgs(AddressZero, mintTo, mintAmount)
            .and.to.emit(token, 'DistributorChanged')
            .withArgs(tokenManager);

        expect(await tokenProxy.implementation()).to.equal(standardizedTokenMintBurn.address);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.balanceOf(mintTo)).to.equal(mintAmount);
        expect(await token.distributor()).to.equal(tokenManager);
        expect(await token.tokenManager()).to.equal(tokenManager);
        await expect(
            standardizedTokenDeployer.deployStandardizedToken(salt, tokenManager, tokenManager, name, symbol, decimals, mintAmount, mintTo),
        ).to.be.revertedWithCustomError(create3Deployer, 'AlreadyDeployed');
    });
});
