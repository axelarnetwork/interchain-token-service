require('dotenv').config();

const { Client, PrivateKey, TokenAssociateTransaction, TokenId, AccountId } = require('@hashgraph/sdk');

// Configure accounts and client
const accPk = PrivateKey.fromStringECDSA(process.env.HEDERA_PK);
console.log('Account EVM address: 0x%s', accPk.publicKey.toEvmAddress());

// const accId = accPk.toAccountId(0, 0);
const accId = AccountId.fromString('0.0.1012');
console.log('Account ID: ', accId.toString());

// TODO allow change from local node to testnet/mainnet
const client = Client.forLocalNode().setOperator(accId, accPk);

/**
 * Convert EVM address to Hedera token ID format
 * @param {string} evmAddress - EVM address (0x...)
 * @returns {string} - Hedera token ID format (0.0.xxxxx)
 */
function evmAddressToTokenId(evmAddress) {
    // Return in Hedera format
    return TokenId.fromSolidityAddress(evmAddress);
}

/**
 * Associate a token with an account
 * @param {Client} client - Hedera client
 * @param {string} tokenId - Token ID in Hedera format (0.0.xxxxx)
 * @param {AccountId} accountId - Account ID
 * @param {PrivateKey} privateKey - Private key
 */
async function associateToken(client, tokenId, accountId, privateKey) {
    const associateTx = new TokenAssociateTransaction().setAccountId(accountId).setTokenIds([tokenId]).freezeWith(client);

    const signTx = await associateTx.sign(privateKey);
    const submitTx = await signTx.execute(client);
    const receipt = await submitTx.getReceipt(client);

    console.log('Token associated with account successfully');
    console.log('Receipt status:', receipt.status.toString());

    return receipt;
}

// CLI functionality
async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.error('Usage: node token-associate.js <token-evm-address>');
        console.error('Example: node token-associate.js 0x52C2B8');
        process.exit(1);
    }

    const tokenEvmAddress = args[0];

    try {
        // Convert EVM address to Hedera token ID format
        const tokenId = evmAddressToTokenId(tokenEvmAddress);
        console.log('Token EVM Address:', tokenEvmAddress);
        console.log('Token ID (Hedera format):', tokenId.toString());

        // Associate the token
        await associateToken(client, tokenId, accId, accPk);

        process.exit(0);
    } catch (error) {
        console.error('Error associating token:', error.message);
        process.exit(1);
    }
}

// Export functions for use as module
module.exports = {
    associateToken,
    evmAddressToTokenId,
};

// Run main function if script is executed directly
if (require.main === module) {
    main().catch(console.error);
}
