# Hedera ITS Support

## Overview

ITS contracts in this repo are modified to support Hedera Token Service. All new interchain tokens will be created via HTS, while existing HTS and ERC20 tokens are supported for registration. New HTS Interchain tokens will have `InterchainTokenService` as the sole Supply Key ("MinterBurner" equivalent in Hedera) and Treasury (the contract that gets the newly minted coins). After minting, the Treasury transfers the tokens to the designated account. Before burning, the tokens are transfered back to the Treasury. ITS uses typical `allowance` and `transferFrom` to move tokens before burning. ITS keeps track of minters and allows for external minting and burning (see `TokenMinter.sol`). Certain ITS features are not supported due to HTS limitations, such as initial supply.

### Hedera-related Notes

- Hedera contract and token "rent" and "expiry" are disabled on Hedera and not supported in this implementation.
- `IERC20` standard methods are supported, including `allowance` and `approve`. See [hip-218](https://hips.hedera.com/hip/hip-218) and [hip-376](https://hips.hedera.com/hip/hip-376). `mint` and `burn` are not supported.
- Unlike an EVM token, the [maximum supply for an HTS token is 2^63](https://docs.hedera.com/hedera/sdks-and-apis/sdks/token-service/define-a-token#token-properties). There's planned support for decimal translation in ITS.
- HTS tokens with the following keys are not supported by ITS: `kycKey`, `wipeKey`, `freezeKey`, `pauseKey`. `adminKey` can update existing keys, but cannot add new keys if they were not set during the creation of the token ([see here](https://docs.hedera.com/hedera/sdks-and-apis/sdks/token-service/update-a-token)).
- `HTS.sol` library is a subset of the Hedera provided system library [HederaTokenService](https://github.com/hashgraph/hedera-smart-contracts/blob/bc3a549c0ca062c51b0045fd1916fdaa0558a360/contracts/system-contracts/hedera-token-service/HederaTokenService.sol). Functions are modified to revert instead of returning response codes.
- Currently new tokens created via HTS EVM system contract can have **only one** Supply Key (Minter).
- Currently new tokens created via HTS EVM system contract must have the Treasury be the creator of the token.
- `createFungibleToken` in `HTS.sol` uses `msg.value` to pay for token creation, alongside regular gas fee.

### ITS-related Notes

- `InterchainTokenService.sol` `execute` is payable, since it needs to pay for the HTS token creation fee. It is assumed that the fee is sent as value. `IAxelarValuedExpressExecutable`, `IAxelarExpressExecutable` and  `IAxelarExecutable` are copied from `@axelar-network/axelar-gmp-sdk-solidity`. All unchanged except for the `execute` method in `IAxelarExecutable` to include the `payable` modifier.
- `InterchainTokenDeployer.sol` `deployedAddress` is not supported, since HTS tokens don't have deterministic addresses.
- `interchainTokenAddress` was removed from `InterchainTokenService.sol`, since HTS tokens don't have deterministic addresses. `registeredTokenAddress` should be used instead.
- `transmitInterchainTransfer` was removed from `InterchainTokenService.sol` since it's meant to be called from an `InterchainToken` contract, which is not used.
- `flowLimit`, `flowOutAmount` and `flowInAmount` are removed from `InterchainTokenService.sol` to reduce the size of the contract.
- When creating a new interchain token, `InterchainTokenService` and `TokenManager` are associated with the token.
- When deploying a new interchain token, a Hedera-specific token-creation fee must be sent as value. For this reason, the `deployInterchainToken` method is payable.
- `initialSupply` isn't supported when deploying a new interchain token. To receive tokens, an account needs to previously associate with the token, thus it cannot immediately receive tokens after creation.
- Both HTS tokens and ERC20 tokens are supported for registration.
- When registering a canonical token, only the `TokenManager` is associated with the token.
- `TokenHandler`'s `_giveInterchainToken` and `_takeInterchainToken` interact with the HTS directly — it is assumed the methods are called by the `InterchainTokenService` contract. `TokenManager` is still used for ERC20 tokens, lock-unlock and flow limits.
- `MINT_BURN` and `MINT_BURN_FROM` Token Manager types are currently unsupported, due to missing support of transferring the Treasury role. If this gets supported in the future, the `TokenManager` can be upgraded.
