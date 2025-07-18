const { AccountId, TokenCreateTransaction, TokenSupplyType, TokenType } = require('@hashgraph/sdk');

function evmAddressToAccountId(evmAddress) {
    return AccountId.fromEvmAddress(evmAddress);
}

async function createHtsToken(hederaClient, operatorPk, name, symbol, decimals = 8, intialSupply = 0) {
    const tokenCreateTx = new TokenCreateTransaction()
        .setTokenName(name)
        .setTokenSymbol(symbol)
        .setTokenType(TokenType.FungibleCommon)
        .setDecimals(decimals)
        .setInitialSupply(intialSupply)
        .setTreasuryAccountId(hederaClient._operator.accountId)
        .setSupplyType(TokenSupplyType.Infinite)
        .setSupplyKey(operatorPk)
        .freezeWith(hederaClient);

    const tokenCreateSign = await tokenCreateTx.sign(operatorPk);
    const tokenCreateSubmit = await tokenCreateSign.execute(hederaClient);
    const tokenCreateRx = await tokenCreateSubmit.getReceipt(hederaClient);
    const tokenId = tokenCreateRx.tokenId;
    const tokenAddress = `0x${tokenId.toSolidityAddress().toLowerCase()}`;

    // console.log(`Token created: ${tokenId.toString()} (EVM Address: ${tokenAddress})`);

    return [tokenAddress, tokenId];
}

module.exports = {
    evmAddressToAccountId,
    createHtsToken,
};
