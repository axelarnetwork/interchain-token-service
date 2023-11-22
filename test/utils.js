'use strict';

const fs = require('fs');
const { ethers, network } = require('hardhat');
const { expect } = require('chai');
const { defaultAbiCoder, keccak256 } = ethers.utils;

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

const isHardhat = network.name === 'hardhat';

const getGasOptions = () => {
    return network.config.blockGasLimit ? { gasLimit: network.config.blockGasLimit.toString() } : { gasLimit: 5e6 }; // defaults to 5M gas for revert tests to work correctly
};

const expectRevert = async (txFunc, contract, error, args) => {
    if (network.config.skipRevertTests) {
        await expect(txFunc(getGasOptions())).to.be.reverted;
    } else {
        if (args) {
            await expect(txFunc(null))
                .to.be.revertedWithCustomError(contract, error)
                .withArgs(...args);
        } else {
            await expect(txFunc(null)).to.be.revertedWithCustomError(contract, error);
        }
    }
};

const getChainId = () => {
    return network.config.chainId;
};

const getPayloadAndProposalHash = async (commandID, target, nativeValue, calldata, timeDelay) => {
    let eta;

    if (timeDelay) {
        const block = await ethers.provider.getBlock('latest');
        eta = block.timestamp + timeDelay - 12; // 12 second buffer for live network tests
    } else {
        eta = 0;
    }

    const proposalHash = keccak256(defaultAbiCoder.encode(['address', 'bytes', 'uint256'], [target, calldata, nativeValue]));

    const payload = defaultAbiCoder.encode(
        ['uint256', 'address', 'bytes', 'uint256', 'uint256'],
        [commandID, target, calldata, nativeValue, eta],
    );

    return [payload, proposalHash, eta];
};

const waitFor = async (timeDelay) => {
    if (isHardhat) {
        await network.provider.send('evm_increaseTime', [timeDelay]);
        await network.provider.send('evm_mine');
    } else {
        await new Promise((resolve) => setTimeout(resolve, timeDelay * 1000));
    }
};

const gasReport = {};
let gasReportScheduled = false;

const writeGasReport = () => {
    const report = Object.entries(gasReport)
        .map(([key, value]) => `${key}\n-${value.toLocaleString().padStart(10)} gas`)
        .join('\n\n');

    fs.writeFileSync('gas.report.log', report);
};

const reportGas = (tx, message) => {
    if (message) {
        tx.then((tx) => tx.wait().then((receipt) => (gasReport[message] = receipt.gasUsed.toNumber())));
    }

    if (!gasReportScheduled) {
        gasReportScheduled = true;
        process.on('exit', writeGasReport);
    }

    return tx;
};

module.exports = {
    getRandomBytes32,
    isHardhat,
    getChainId,
    getGasOptions,
    expectRevert,
    getPayloadAndProposalHash,
    waitFor,
    reportGas,
};
