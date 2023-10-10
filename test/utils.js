const { ethers, network } = require('hardhat');
const { expect } = require('chai');
const { defaultAbiCoder, keccak256 } = ethers.utils;

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

const getGasOptions = () => {
    return network.config.blockGasLimit ? { gasLimit: network.config.blockGasLimit.toString() } : { gasLimit: 5e6 }; // defaults to 5M gas for revert tests to work correctly
};

const expectRevert = async (txFunc, contract, error) => {
    if (network.config.skipRevertTests) {
        await expect(txFunc(getGasOptions())).to.be.reverted;
    } else {
        await expect(txFunc(null)).to.be.revertedWithCustomError(contract, error);
    }
};

const getChainId = () => {
    return network.config.chainId;
};

module.exports = {
    getRandomBytes32,
    getChainId,
    getGasOptions,
    expectRevert,
};
