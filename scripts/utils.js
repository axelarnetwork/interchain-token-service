const { ethers } = require('hardhat');
const { defaultAbiCoder, keccak256 } = ethers.utils;

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
    await gateway.approveContractCall(params, commandId).then((tx) => tx.wait);

    return commandId;
}

module.exports = {
    getRandomBytes32,
    approveContractCall,
};
