# Interchain Token Service Design Notes

## Introduction

This project aims to provide a platform that enables tokens of all kinds to go cross-chain. To achieve this we need a cross-chain communication protocol, that can reliably pass information through chains. The Axelar Network is used for this design, but it is possible to adjust some of the contracts to use a different network.

For the purposes of this document we will use two keywords: deployer, the person who creates the bridge and user, the person using a bridge.

## Architecture

The main workflow of a bridge is the following:
- Obtains `x` token from the user on chain A
- Send a message to chain B indicating that this happened, and where the token should go to
- Receive the above message, and hand `x` token to the appropriate address

For this to be a proper bridge it should be possible to perform the above steps for any supported chain being 'chain A' and 'chain B'. There are multiple different possible configurations for any bridge, and we wanted to make it as easy as possible for deployers to get what they want, while making it cheap and easy for users to get their tokens across chains as well.

The workflow described below is facilitated by 2 smart contracts the [`InterchainTokenService`](./contracts/interchainTokenService/InterchainTokenService.sol) and the [`InterchainTokenFactory`](./contracts/InterchainTokenFactory.sol). The `InterchainTokenService` deploys `TokenManagers` which register each token and is responsible for sending and receiving messages. Each bridge will result in a new `TokenManager` with a unique `interchainTokenId`. There are a few different options that deployers have to obtain different kinds of `TokenManagers` with different qualities. The `InterchainTokenFactory` allows to deploy bridges that have certain quarantees, like fixed supply tokens, or bridging pre-existing tokens.

Note that a lot of the design choises were made with supporting non-EVM chains in mind.

### Custom Bridges

Most projects that look to go cross-chain nowadays have more complex needs that the ones covered by Canonical Bridges: they often need custom `ERC20` designs, and will sometimes want to have additional power over the bridge. This is where the `InterchainTokenService` shines, deployers can claim certain `InterchainTokenIds` only based on their `address`, and a `salt` they provide, and specify any kind of `TokenManager` to be deployed and either manage an external `ERC20` or an `InterchainToken`. Users using Custom Bridges need to trust the deployers as they could easily confiscate the funds of users if they wanted to, same as any `ERC20` distributor could confiscate the funds of users. There are currently four kinds of possible `TokenManagers` available, but this number might increase in the future, as we find more potential uses for the `InterchainTokenService`.
- Lock/Unlock: This `TokenManager` will simply transfer tokens from a user to itself or vice versa to initiate/fulfill cross-chain transfers
- Lock/Unlock Fee: This `TokenManager` works like the one above, but accounts for tokens that have a fee-on-transfer giving less tokens to be locked than what it actually transferred.
- Mint/Burn: This `TokenManager` will `burn`/`mint` tokens from/to the user to initiate/fulfill cross-chain transfers. Tokens used with this kind of `TokenManager` need to be properly permissioned to allow for this behaviour.
- Mint/BurnFrom: This `TokenManager` is the same as the one above, but uses `burnFrom` instead of `burn` which is the standard for some tokens and typically requires an approval.

### Interchain Token Factory

The `InterchainTokenFactory` can remove some of the power from deployers to be able to obtain bridges that have more guarantees/less trust assumptions. There are two options that it provides, one for Canonical Bridges, and one for `InterchainTokens`.

Most current bridge designs aim to get a pre-existing, popular token to different chains that can benefit from the liquidity. When they do so the resulting token, called [`InterchainToken`](./contracts/interchain-token/InterchainToken.sol) in this project, will only have basic functionality that enables users to transfer their token and use it with general use smart contracts like De-Fi applications. This is certainly powerfull, and has the benefit that as long as the pre-existing `ERC20` implemention and the bridge function properly everything run as expected. We wanted to include this design for the `InterchainTokenService` as well, so deployers can deploy a Canonical Bridge for any token they want, and this can be done only once per pre-existing `ERC20`. This can be done throught the `InterchainTokenFactory` to remove the ability of deployers to confiscate funds, making such bridges have fewer trust assumtions.

`InterchainTokens` deployed through the service have no guarantees: they could have missmatching names/symbols/decimals, and again the depoyer needs to be trusted as they have a lot of power over them. Deploying such tokens throught the `InterchainTokenFactory` however removes those powers, and can result in fixed supply tokens as well, or have a `Minter` that can manage the token supply.

## Interchain Tokens

We designed an [interface](./contracts/interfaces/IInterchainTokenStandard.sol) allong a [example implementation](./contracts/interchain-token/InterchainTokenStandard.sol) of an ERC20 that can use the `InterchainTokenService` internally. This has the main benefit that for `TokenManagers` that require user approval (Lock/Unlock, Lock/Unlock Fee and Mint/BurnFrom) the token can provide this approval within the same call, providing better UX for users, and saving them some gas.

## Interchain Communication Spec

The messages going through the Axelar Network between `InterchainTokenServices` need to have a certain format to be understood properly. We chose to use `abi` encoding as it is easy to use in EVM chains, which are front and center of the programmable bockchains, and they are easy to implement in other ecosystems which tend to be more gas efficient usually. There are currently three supported message types: `INTERHCAIN_TRANSFER`, `DEPLOY_INTERCHAIN_TOKEN`, `DEPLOY_TOKEN_MANAGER`.

### `INTERCHAIN_TRANSFER`

This message has the following data encoded and should only be sent afer the proper tokens have been procurred by the service. It should result in the proper funds being transferred to the user at the destionation chain.

| Name | Type | Description |
| --- | --- | --- |
| selector | `uint256` | Will always have a value of `0` |
| tokenId | `bytes32` | The `interchainTokenId` of the token being transferred |
| source address | `bytes` | The address of the sender, encoded as bytes to account for different chain architectures |
| destination address | `bytes` | The address of the sender, encoded as bytes as well |
| amount | `uint256` | The amount of token being send, not accounting for decimals (1 `ETH` would be 10<sup>18</sup>) |
| data | `bytes` | Either empty, for just a transfer, or any data to be passed to the destination address as a contract call |

### `DEPLOY_INTERCHAIN_TOKEN`

This message has the following data encoded and should only be sent afer the `interchainTokenId` has been properly produced (each user should not be able to clain any `interchainTokenId`)

| Name | Type | Description |
| --- | --- | --- |
| selector | `uint256` | Will always have a value of `1` |
| tokenId | `bytes32` | The `interchainTokenId` of the token being deployed |
| name | `string` | The name for the token |
| symbol | `string` | The symbol for the token |
| decimals | `uint8` | The decimals for the token |
| minter | `bytes` | An address on the destination chain that can mint/burn the deployed token on the destination chain, empty for no minter |

### `DEPLOY_TOKEN_MANAGER`

This message has the following data encoded and should only be sent afer the proper tokens have been procurred by the service. It should result in the proper funds being transferred to the user at the destionation chain.

| Name | Type | Description |
| --- | --- | --- |
| selector | `uint256` | Will always have a value of `2` |
| tokenId | `bytes32` | The `interchainTokenId` of the token being deployed |
| token manager type | `uint256` | The type of the token manager, look at the [code](./contracts/interfaces/ITokenManagerType.sol) for details on EVM, but it could be different for different architectures |
| params | `bytes` | The parameters for the token manager deployments, look [here](./contracts/token-manager/TokenManager.sol#L179) for details on EVM chain parameters |
