const { ethers, network } = require('hardhat');
const { deployContract } = require('./deploy');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256 } = ethers.utils;
const { expect } = require('chai');

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

async function approveContractCall(
    gateway,
    sourceChain,
    sourceAddress,
    contractAddress,
    payload,
    sourceTxHash = getRandomBytes32(),
    sourceEventIndex = 0,
    commandId = getRandomBytes32(),
) {
    const params = defaultAbiCoder.encode(
        ['string', 'string', 'address', 'bytes32', 'bytes32', 'uint256'],
        [sourceChain, sourceAddress, contractAddress, keccak256(payload), sourceTxHash, sourceEventIndex],
    );
    await (await gateway.approveContractCall(params, commandId)).wait();

    return commandId;
}

async function deployGatewayToken(gateway, tokenName, tokenSymbol, tokenDecimals, walletForExternal) {
    let tokenAddress = AddressZero;

    if (walletForExternal) {
        const token = await deployContract(walletForExternal, 'GatewayToken', [tokenName, tokenSymbol, tokenDecimals]);
        tokenAddress = token.address;
    }

    const params = defaultAbiCoder.encode(
        ['string', 'string', 'uint8', 'uint256', 'address', 'uint256'],
        [tokenName, tokenSymbol, tokenDecimals, 0, tokenAddress, 0],
    );
    const commandId = getRandomBytes32();
    await (await gateway.deployToken(params, commandId)).wait();
}

// const getGasOptions = () => {
//     return network.config.blockGasLimit ? { gasLimit: network.config.blockGasLimit.toString() } : { gasLimit: 5e6 }; // defaults to 5M gas for revert tests to work correctly
// };

const getGasOptions = () => {
    return { gasLimit: 5000000 };
};

const expectRevert = async (txFunc, contract, error) => {
    if (network.config.skipRevertTests) {
        await expect(txFunc(getGasOptions())).to.be.reverted;
    } else {
        await expect(txFunc(null)).to.be.revertedWithCustomError(contract, error);
    }
};

module.exports = {
    getChainId: async () => await network.provider.send('eth_chainId'),
    getRandomBytes32,
    approveContractCall,
    deployGatewayToken,
    getGasOptions,
    expectRevert,
};
