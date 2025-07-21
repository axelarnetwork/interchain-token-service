const { Client: HederaClient, PrivateKey: HederaPrivateKey, AccountId: HederaAccountId } = require('@hashgraph/sdk');

function hederaClientFromHardhatConfig(networkConfig) {
    const hederaConsensusUrl = networkConfig.consensusUrl;
    const hederaPk = HederaPrivateKey.fromStringECDSA(networkConfig.operatorKey);
    const hederaOperatorId = HederaAccountId.fromString(networkConfig.operatorId);
    const hederaNodeId = HederaAccountId.fromString(networkConfig.nodeId);

    const hederaConsensusHost = hederaConsensusUrl.replace('http://', '').replace('https://', '');
    const hederaClient = HederaClient.forNetwork({
        [hederaConsensusHost]: hederaNodeId,
    });
    hederaClient.setOperator(hederaOperatorId, hederaPk);

    console.log(`  Using Hedera Client Configuration:`);
    console.log(`\tMirror Node URL: ${networkConfig.url}`);
    console.log(`\tConsensus URL: ${hederaConsensusUrl}`);
    console.log(`\tOperator PK: ${networkConfig.operatorKey}`);
    console.log(`\tOperator ID: ${hederaOperatorId.toString()}`);
    console.log(`\tOperator Address: ${hederaOperatorId.toSolidityAddress()}`);
    console.log(`\tNode ID: ${hederaNodeId.toString()}`);

    return { hederaClient, hederaPk, hederaOperatorId };
}

module.exports = {
    hederaClientFromHardhatConfig,
};
