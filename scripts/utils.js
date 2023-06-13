const { ethers } = require('hardhat');
const { deployContract } = require('./deploy');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256 } = ethers.utils;

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [new Date().getTime()]));
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

module.exports = {
    getRandomBytes32,
    approveContractCall,
    deployGatewayToken,
};
