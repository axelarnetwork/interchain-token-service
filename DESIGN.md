# Interchain Token Service Design Notes

## Introduction

This project aims to provide a platform that enables tokens of all kinds to go cross-chain. To achieve this we need a cross-chain communication protocol that can reliably pass information between chains. The Axelar Network is used for this design, but it is possible to adjust some of the contracts to use a different network.

For the purposes of this document, we will use two keywords: 'deployer,' the person who creates the bridge, and 'user,' the person using the bridge.

## Architecture

The main workflow of a bridge is as follows:

-   Obtain `x` token from the user on chain A
-   Send a message to chain B indicating that this has happened, specifying where the token should go
-   Receive the message above, and transfer `x` token to the appropriate destination address

For the bridge to function effectively, it should be capable of executing these steps between any two supported chains, designated as 'Chain A' and 'Chain B'. There are multiple different possible configurations for any such bridge. Our goal is to make bridging as easy as possible for deployers to get what they want, while also making it cheap and easy for users to transfer their tokens between chains.

The workflow described below is facilitated by 2 smart contracts the [`InterchainTokenService`](./contracts/InterchainTokenService.sol) and the [`InterchainTokenFactory`](./contracts/InterchainTokenFactory.sol). The `InterchainTokenService` deploys `TokenManagers` which register each token and is also responsible for sending and receiving messages. Each bridge will result in a new `TokenManager` with a unique `interchainTokenId`. Deployers have a few different options when creating `TokenManagers`, with each option representing a different `TokenManager` type with distinct qualities. The `InterchainTokenFactory` allows developers to deploy bridges that have certain guarantees, such as fixed supply tokens, or bridging pre-existing tokens.

It is important to note that a lot of the design choices were made with supporting non-EVM chains in mind.

### Custom Bridges

Most projects that look to go cross-chain nowadays have more complex needs than the ones covered by Canonical Bridges: they often need custom `ERC20` designs, and will sometimes want to have additional power over the bridge. This is where the `InterchainTokenService` shines. Deployers can claim certain `InterchainTokenIds` derived solely from their `address`, and a `salt` that they provide, and specify any kind of `TokenManager` to be deployed to either manage an external `ERC20` or an `InterchainToken`. Users using Custom Bridges need to trust the deployers as they could easily confiscate users' funds if they wanted to, the same way that `ERC20` distributors could confiscate the users' funds. There are currently four `TokenManagers` types available, but this number may increase in the future as we find more potential uses for the `InterchainTokenService`.

-   Lock/Unlock: This `TokenManager` will simply transfer tokens from a user to itself or vice versa to initiate/fulfill cross-chain transfers.
-   Lock/Unlock Fee: This `TokenManager` works like the one above, but accounts for tokens that have a fee-on-transfer giving less tokens to be locked than what it actually transferred.
-   Mint/Burn: This `TokenManager` will `burn`/`mint` tokens from/to the user to initiate/fulfill cross-chain transfers. Tokens used with this kind of `TokenManager` need to be properly permissioned to allow for this behaviour.
-   Mint/BurnFrom: This `TokenManager` is the same as the one above, but uses `burnFrom` instead of `burn` which is the standard for some tokens and typically requires an approval.

### Interchain Token Factory

The `InterchainTokenFactory` can remove some of the power from deployers to be able to obtain bridges that have more guarantees/less trust assumptions. There are two options that it provides, one for Canonical Bridges, and one for `InterchainTokens`.

Most current bridge designs aim to transfer a pre-existing, popular token to different chains that can benefit from the liquidity. When they transfer a pre-existing token, the resulting token, called [`InterchainToken`](./contracts/interchain-token/InterchainToken.sol) in this project, will only have basic functionality that enables users to transfer their token and use it with general use smart contracts such as De-Fi applications. This is certainly powerful and has the benefit that as long as the pre-existing `ERC20` implemention and the bridge function properly, everything will run as expected. We included this design for the `InterchainTokenService` so deployers can deploy a Canonical Bridge for any token they choose, once for each pre-existing `ERC20` implementation. This can also be done through the `InterchainTokenFactory` to remove the ability of deployers to confiscate funds, making such bridges have fewer trust assumptions.

`InterchainTokens` deployed through the service have no guarantees: they could have mismatching names/symbols/decimals, and again the deployer needs to be trusted as they have a lot of power over them. Deploying such tokens through the `InterchainTokenFactory`, however, removes this power, and can result in fixed supply tokens as well, or designate a `Minter` that can manage the token supply.

## Interchain Tokens

We designed an [interface](./contracts/interfaces/IInterchainTokenStandard.sol) along with an [example implementation](./contracts/interchain-token/InterchainTokenStandard.sol) of an ERC20 that can use the `InterchainTokenService` internally. This has the main benefit that for `TokenManagers` that require user approval (Lock/Unlock, Lock/Unlock Fee and Mint/BurnFrom), the token can provide this approval within the same call, providing better UX for users, and saving them some gas.

## Interchain Communication Spec

The messages going through the Axelar Network between `InterchainTokenServices` need to have a consistent format to be understood properly. We chose to use `abi` encoding because it is easy to use in EVM chains, which are at the front and center of programmable blockchains, and because it is easy to implement in other ecosystems which tend to be more gas efficient. There are currently three supported message types: `INTERCHAIN_TRANSFER`, `DEPLOY_INTERCHAIN_TOKEN`, `DEPLOY_TOKEN_MANAGER`.

### `INTERCHAIN_TRANSFER`

This message is used to transfer tokens between chains. The tokens are handled appropriately on the source chain (lock/burn etc.), and then this message is sent to the ITS contract on the remote chain which sends the tokens to the destination address.

| Name                | Type      | Description                                                                                               |
| ------------------- | --------- | --------------------------------------------------------------------------------------------------------- |
| messageType         | `uint256` | Will always have a value of `0`                                                                           |
| tokenId             | `bytes32` | The `interchainTokenId` of the token being transferred                                                    |
| source address      | `bytes`   | The address of the sender, encoded as bytes to account for different chain architectures                  |
| destination address | `bytes`   | The address of the recipient, encoded as bytes as well                                                    |
| amount              | `uint256` | The amount of token being send, not accounting for decimals (1 `ETH` would be 10<sup>18</sup>)            |
| data                | `bytes`   | Either empty, for just a transfer, or any data to be passed to the destination address as a contract call |

### `DEPLOY_INTERCHAIN_TOKEN`

This message is used to deploy an `InterchainToken` on a remote chain, that corresponds to the `tokenId` of a local ERC-20 token registered in ITS. This allows a user to deploy tokens to remote chains from a single source chain, instead of having to make a tx on each chain. It also allows the implementation on each chain to be flexible (e.g. `tokenId` derivation can be different on remote chains).

| Name     | Type      | Description                                                                                                             |
| -------- | --------- | ----------------------------------------------------------------------------------------------------------------------- |
| messageType | `uint256` | Will always have a value of `1`                                                                                         |
| tokenId  | `bytes32` | The `interchainTokenId` of the token being deployed                                                                     |
| name     | `string`  | The name for the token                                                                                                  |
| symbol   | `string`  | The symbol for the token                                                                                                |
| decimals | `uint8`   | The decimals for the token                                                                                              |
| minter   | `bytes`   | An address on the destination chain that can mint/burn the deployed token on the destination chain, empty for no minter |

### `DEPLOY_TOKEN_MANAGER`

This message is used to deploy a token manager on a remote chain, that corresponds to a local token manager. This is useful to link custom tokens via ITS with the same tokenId.

| Name               | Type      | Description                                                                                                                                                               |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| messageType        | `uint256` | Will always have a value of `2`                                                                                                                                           |
| tokenId            | `bytes32` | The `interchainTokenId` of the token being deployed                                                                                                                       |
| token manager type | `uint256` | The type of the token manager, look at the [code](./contracts/interfaces/ITokenManagerType.sol) for details on EVM, but it could be different for different architectures |
| params             | `bytes`   | The parameters for the token manager deployments, look [here](./contracts/token-manager/TokenManager.sol#L191) for details on EVM chain parameters                        |

### `SEND_TO_HUB`

This message is used to route an ITS message via the ITS Hub. The ITS Hub applies certain security checks, and then routes it to the true destination chain. This mode is enabled if the trusted address corresponding to the destination chain is set to the ITS Hub identifier.

| Name               | Type      | Description                                                                                                                                                               |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| messageType        | `uint256` | Will always have a value of `3`                                                                                                                                           |
| destinationChain   | `string`  | The true destination chain for the ITS call                                                                                                                       |
| payload            | `bytes`   | The actual ITS message that's being routed through ITS Hub

### `RECEIVE_FROM_HUB`

This message is used to receive an ITS message from the ITS Hub. The ITS Hub applies certain security checks, and then routes it to the ITS contract. The message is accepted if the trusted address corresponding to the original source chain is set to the ITS Hub identifier.

| Name               | Type      | Description                                                                                                                                                               |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| messageType        | `uint256` | Will always have a value of `4`                                                                                                                                           |
| sourceChain        | `string`  | The original source chain for the ITS call                                                                                                                       |
| payload            | `bytes`   | The actual ITS message that's being routed through ITS Hub
