'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    BigNumber,
    constants: { MaxUint256 },
} = ethers;
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = chai;
const { expectRevert, isHardhat, waitFor } = require('./utils');
const { deployContract } = require('../scripts/deploy');

let ownerWallet;

before(async () => {
    const wallets = await ethers.getSigners();
    ownerWallet = wallets[0];
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

    beforeEach(async () => {
        await nextEpoch();
    });

    it('Should calculate hardcoded constants correctly', async () => {
        await expect(deployContract(ownerWallet, `TestFlowLimit`, [])).to.not.be.reverted;
    });

    it('Should be able to set the flow limit', async () => {
        await expect(test.setFlowLimit(flowLimit)).to.emit(test, 'FlowLimitSet').withArgs(tokenId, ownerWallet.address, flowLimit);

        expect(await test.flowLimit()).to.equal(flowLimit);
    });

    it('Should test flow in', async () => {
        for (let i = 0; i < flowLimit; i++) {
            await test.addFlowIn(1).then((tx) => tx.wait());
            expect(await test.flowInAmount()).to.equal(i + 1);
        }

        await expectRevert((gasOptions) => test.addFlowIn(1, gasOptions), test, 'FlowLimitExceeded', [
            flowLimit,
            flowLimit + 1,
            test.address,
        ]);

        await nextEpoch();

        expect(await test.flowInAmount()).to.equal(0);

        await test.addFlowIn(flowLimit).then((tx) => tx.wait());
    });

    it('Should test flow out', async () => {
        for (let i = 0; i < flowLimit; i++) {
            await test.addFlowOut(1).then((tx) => tx.wait());
            expect(await test.flowOutAmount()).to.equal(i + 1);
        }

        await expectRevert((gasOptions) => test.addFlowOut(1, gasOptions), test, 'FlowLimitExceeded', [
            flowLimit,
            flowLimit + 1,
            test.address,
        ]);

        await nextEpoch();

        expect(await test.flowOutAmount()).to.equal(0);

        await test.addFlowOut(flowLimit).then((tx) => tx.wait());
    });

    const flipFlows = (flows) => flows.map((f) => (f.in ? { out: f.in } : { in: f.out }));

    const getErrorArgs = async (error, isInbound, flowAmount, flowIn, flowOut, flowLimit, test) => {
        const contract = test.address;

        switch (error) {
            case 'FlowAmountOverflow': {
                const flow = isInbound ? await test.flowInAmount() : await test.flowOutAmount();
                return [flowAmount, BigNumber.from(flow), contract];
            }

            case 'FlowLimitExceeded': {
                const flow = isInbound ? flowIn.add(flowAmount) : flowOut.add(flowAmount);
                const reverseFlow = isInbound ? flowOut : flowIn;
                const netFlow = flow.sub(reverseFlow).abs();
                return [flowLimit, netFlow, contract];
            }

            case 'FlowAmountExceededLimit':
                return [flowLimit, flowAmount, contract];

            default:
                throw new Error(`Unknown error type passed to getErrorArgs: ${error}`);
        }
    };

    const executeTestCases = (testCases, expectedError) => {
        // Flipped test cases should produce the same expected behavior
        const allCases = [
            ...testCases,
            ...testCases.map(({ flowLimit, flows }) => ({
                flowLimit,
                flows: flipFlows(flows),
            })),
        ];

        for (const { flowLimit, flows } of allCases) {
            const label = expectedError
                ? `Should revert with ${expectedError} (flowLimit=${flowLimit}, steps=${flows.length})`
                : `Should allow valid flow patterns (flowLimit=${flowLimit}, steps=${flows.length})`;

            it(label, async () => {
                await nextEpoch();
                await test.setFlowLimit(flowLimit).then((tx) => tx.wait());

                let flowIn = BigNumber.from(0);
                let flowOut = BigNumber.from(0);
                const lastIndex = flows.length - 1;

                for (const [index, flow] of flows.entries()) {
                    const isInbound = flow.in != null;
                    const flowAmount = BigNumber.from(flow.in || flow.out);
                    const addFlowFn = isInbound ? test.addFlowIn : test.addFlowOut;

                    if (index === lastIndex && expectedError) {
                        const expectedArgs = await getErrorArgs(expectedError, isInbound, flowAmount, flowIn, flowOut, flowLimit, test);
                        await expectRevert((gasOptions) => addFlowFn(flowAmount, gasOptions), test, expectedError, expectedArgs);
                        return;
                    }

                    await addFlowFn(flowAmount).then((tx) => tx.wait());

                    if (isInbound) {
                        flowIn = flowIn.add(flowAmount);
                    } else {
                        flowOut = flowOut.add(flowAmount);
                    }
                }
            });
        }
    };

    describe('Should succeed on valid flows', () => {
        const testCases = [
            { flowLimit: 1, flows: [{ in: 1 }] },
            { flowLimit: 1000, flows: [{ in: 1000 }] },
            { flowLimit: MaxUint256, flows: [{ in: MaxUint256 }] },
            {
                flowLimit: 1,
                flows: [{ in: 1 }, { out: 1 }, { in: 1 }],
            },
            {
                flowLimit: 10,
                flows: [{ in: 5 }, { in: 5 }, { out: 10 }, { out: 10 }, { in: 1 }, { in: 10 }, { in: 9 }],
            },
            {
                flowLimit: MaxUint256,
                flows: [{ in: 1 }, { out: 1 }, { in: 1 }],
            },
            {
                flowLimit: MaxUint256,
                flows: [{ in: MaxUint256.sub(1) }, { out: MaxUint256 }, { in: 1 }],
            },
        ];

        executeTestCases(testCases);
    });

    describe('Should revert with FlowAmountExceededLimit', () => {
        const testCases = [
            { flowLimit: 1, flows: [{ in: 2 }] },
            { flowLimit: MaxUint256.sub(1), flows: [{ in: MaxUint256 }] },
            { flowLimit: 1, flows: [{ in: 1 }, { out: 2 }] },
            { flowLimit: MaxUint256.sub(1), flows: [{ in: 1 }, { out: MaxUint256 }] },
            { flowLimit: 1, flows: [{ in: 1 }, { out: 1 }, { out: 1 }, { in: 2 }] },
        ];

        executeTestCases(testCases, 'FlowAmountExceededLimit');
    });

    describe('Should revert with FlowAmountOverflow', () => {
        const testCases = [
            { flowLimit: MaxUint256, flows: [{ in: MaxUint256 }, { in: 1 }] },
            { flowLimit: MaxUint256.sub(1), flows: [{ in: 1 }, { out: 2 }, { out: MaxUint256.sub(1) }] },
            { flowLimit: MaxUint256.sub(1), flows: [{ in: 10 }, { out: 1 }, { in: MaxUint256.sub(2) }] },
            {
                flowLimit: MaxUint256.div(2).add(2),
                flows: [{ in: MaxUint256.div(2) }, { out: MaxUint256.div(2) }, { in: MaxUint256.div(2).add(2) }],
            },
        ];

        executeTestCases(testCases, 'FlowAmountOverflow');
    });

    describe('Should revert with FlowLimitExceeded', () => {
        const testCases = [
            { flowLimit: 1, flows: [{ in: 1 }, { in: 1 }] },
            { flowLimit: 10, flows: [{ in: 10 }, { out: 10 }, { in: 1 }, { in: 10 }] },
            { flowLimit: MaxUint256.sub(1), flows: [{ in: MaxUint256.sub(1) }, { in: 1 }] },
            { flowLimit: MaxUint256.sub(2), flows: [{ in: 1 }, { out: MaxUint256.sub(2) }, { out: 2 }] },
            { flowLimit: MaxUint256.div(2), flows: [{ in: MaxUint256.div(2) }, { out: 1 }, { in: 2 }] },
        ];

        executeTestCases(testCases, 'FlowLimitExceeded');
    });
});
