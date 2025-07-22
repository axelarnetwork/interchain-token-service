# Hedera ITS Support

## Overview

ITS contracts in this repo are modified to support Hedera Token Service. All new Interchain Token will be created via HTS, while existing HTS and ERC20 tokens are supported for registration.

New HTS Interchain Tokens will have their Token Manager as the sole Supply Key ("MinterBurner" equivalent in Hedera) and Treasury (the contract that gets the newly minted coins). After minting, the Treasury transfers the tokens to the designated account. Before burning, the tokens are transfered back to the Treasury. Token Managers use typical `allowance` and `transferFrom` to move tokens before burning. Token Manager keeps track of minters and allows for external minting and burning (see `Minter.sol`). Certain ITS features are not supported due to HTS limitations, such as deploying a new Interchain Token with initial supply.

Since the `createFungibleToken` precompile in Hedera requires a fee to be sent as value, an `WHBAR` contract (`WETH` equivalent) is used to hold the HBAR used for token creation. `InterchainTokenService` transfers certain amount of `WHBAR` to the newly deploying `TokenManagerProxy` contract. The `TokenManagerProxy` contract, during constructor, withdraws HBAR from `WHBAR`, and sends it to `InterchainTokenDeployer`, which finally uses it to pay for the token creation.

The responsibility of keeping ITS funded on the WHBAR contract lies with the deployer, it is assumed that a top-up mechanism is in place to ensure the contract has enough WHBAR to create new tokens.

![Deploy New Interchain Token Flow](./diagrams/deploy_interchain_token.png)

![Mint Native Interchain Token](./diagrams/native_token_minting.png)

![Register Custom HTS Token](./diagrams/register_custom_hts_token.png)

### Deploying with Initial Supply

Initial supply is currently not supported when deploying a new Interchain Token on Hedera. To receive tokens, an account needs to previously associate with the token, thus it cannot immediately receive tokens after creation. Associating an account using a smart contract [is not supported](https://hedera.com/blog/get-ready-for-the-updated-security-model-of-the-hedera-smart-contract-service-by-july-2023).

However there is an [Automatic Token Associations](https://docs.hedera.com/hedera/core-concepts/accounts/account-properties#automatic-token-associations) feature in Hedera, which allows accounts to approve a number of automatic token associations (airdrops) without needing to explicitly associate with each token. The only way to reliably tell if an account can receive a new token is by reading the property for the account and checking if the value is `-1` (unlimited associations).

There is an optimistic approach to this, where it is assumed the account has unlimited associations and can receive the token. However if the transaction reverts due to it not being able to receive the token, [gas will be nonetheless charged](https://docs.hedera.com/hedera/core-concepts/smart-contracts/gas-and-fees). This is undesirable, since Hedera charges at minimum 80% of the gas limit.

Another approach is to have the Relayer [check](https://docs.hedera.com/hedera/sdks-and-apis/rest-api/accounts#get-api-v1-accounts-idoraliasorevmaddress) if the account can receive the token before deploying it, but this requires customisations to the Relayer, which is again not desirable.

This behaviour can be changed in the future by upgrading the `InterchainTokenFactory` contract to support initial supply, but for now it is not supported.

### Hedera Tokens as ERC20

Hedera tokens support so-called facades, which allow them to be used as ERC20 tokens. A number of standard methods are supported, like `name`, `balanceOf`, `transfer`, `transferFrom`, `approve`, `allowance`, etc. See [hip-218](https://hips.hedera.com/hip/hip-218) and [hip-376](https://hips.hedera.com/hip/hip-376). `mint` and `burn` are not supported.

Unlike a regular ERC20 token, HTS tokens don't emit `Transfer` to and from the zero address on mint and burn.

Association-related methods are also supported, like `associate`, `dissociate`, and `isAssociated`. See [hip-719](https://hips.hedera.com/hip/hip-719) for more details.

### `InterchainTokenExecutable`

To receive tokens, an `InterchainTokenExecutable` contract needs to previously be associated with the token. The mechanism is left to the end contract, but one possible way is to have a function like so:

```solidity
function associateWithToken(address tokenAddress_) external {
    IHRC719(tokenAddress_).associate();
}
```

It uses the [`IHRC719`](./IHRC719.sol) interface to call the `associate` method on the token contract, which will associate the contract with the token. There is no need to interact with the `HTS` library or the precompile directly, as the `IHRC719` interface abstracts that away.

### Hedera-related Notes

- Hedera contract and token "rent" and "expiry" are disabled on Hedera and not supported in this implementation.
- Unlike a regular ERC20 token, the [maximum supply for an HTS token is 2^63](https://docs.hedera.com/hedera/sdks-and-apis/sdks/token-service/define-a-token#token-properties). There's planned support for decimal translation in ITS.
- HTS tokens with the following keys are not supported by ITS: `kycKey`, `wipeKey`, `freezeKey`, `pauseKey`. `adminKey` can update existing keys, but cannot add new keys if they were not set during the creation of the token ([see here](https://docs.hedera.com/hedera/sdks-and-apis/sdks/token-service/update-a-token)).
- `HTS.sol` library is a subset of the Hedera provided system library [HederaTokenService](https://github.com/hashgraph/hedera-smart-contracts/blob/bc3a549c0ca062c51b0045fd1916fdaa0558a360/contracts/system-contracts/hedera-token-service/HederaTokenService.sol). Functions are modified to revert instead of returning response codes.
- Currently new tokens created via HTS EVM system contract can have **only one** Supply Key (Minter).
- Currently new tokens created via HTS EVM system contract must have the Treasury be the creator of the token.
- `WHBAR` contracts used can be found [here](https://docs.hedera.com/hedera/core-concepts/smart-contracts/wrapped-hbar-whbar#contract-deployments).

### ITS-related Notes

- `MINT_BURN` and `MINT_BURN_FROM` Token Manager types are currently unsupported, due to missing support of transferring the Treasury role. If this gets supported in the future, the `TokenManager` can be upgraded.
- When registering a canonical token, only the `TokenManager` is associated with the token.
- `InterchainTokenDeployer.sol` `deployedAddress` is not supported, since HTS tokens don't have deterministic addresses.
- `interchainTokenAddress` was removed from `InterchainTokenService.sol`, since HTS tokens don't have deterministic addresses. `registeredTokenAddress` should be used instead.
- `transmitInterchainTransfer` was removed from `InterchainTokenService.sol` since it's meant to be called from an `InterchainToken` contract, which is not used.
- When creating a new interchain token, `TokenManager` is automatically associated with the token, as the creator.
- Both HTS tokens and ERC20 tokens are supported for registration.
