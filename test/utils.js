const { ethers, network } = require('hardhat');
const { expect } = require('chai');
const { defaultAbiCoder, keccak256 } = ethers.utils;

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

const getGasOptions = () => {
    return network.config.blockGasLimit ? { gasLimit: network.config.blockGasLimit.toString() } : { gasLimit: 5e6 }; // defaults to 5M gas for revert tests to work correctly
};

const isHardhat = network.name === 'hardhat';

const expectRevert = async (txFunc, contract, error) => {
    if (network.config.skipRevertTests) {
        await expect(txFunc(getGasOptions())).to.be.reverted;
    } else {
        await expect(txFunc(null)).to.be.revertedWithCustomError(contract, error);
    }
};

const waitFor = async (timeDelay) => {
    if (isHardhat) {
        await network.provider.send('evm_increaseTime', [timeDelay]);
        await network.provider.send('evm_mine');
    } else {
        await new Promise((resolve) => setTimeout(resolve, timeDelay * 1000));
    }
};

const getChainId = () => {
    return network.config.chainId;
};

module.exports = {
    getRandomBytes32,
    getChainId,
    getGasOptions,
    isHardhat,
    expectRevert,
    waitFor,
};
