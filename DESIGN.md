# Interchain Token Service Design Notes

## Introduction

This project aims to provide a platform that enables tokens of all kinds to go interchain. To achieve this we need an interchain communication protocol, that can reliably pass information through chains. The Axelar Network is used for this design, but it is possible to adjust some of the contracts to use a different network.

For the purposes of this document we will use two keywords: deployer, the person who creates the bridge and user, the person using a bridge.

## Architecture

The main workflow of a bridge is the following:

-   Obtains `x` token from the user on chain A
-   Send a message to chain B indicating that this happened, and where the token should go to
-   Receive the above message, and hand `x` token to the appropriate address

For this to be a proper bridge it should be possible to perform the above steps for any supported chain being 'chain A' and 'chain B'. There are multiple different possible configurations for any bridge, and we wanted to make it as easy as possible for deployers to get what they want, while making it cheap and easy for users to get their tokens across chains as well.

The workflow described below is facilitated by 2 smart contracts the [`InterchainTokenService`](./contracts/interchainTokenService/InterchainTokenService.sol) and the [`TokenManager`](./contracts/tokenManager/TokenManager.sol). The `TokenManager` handles tokens and is the input side for all requests, and the `InterchainTokenService` deploys `TokenManagers` and is responsible for sending and receiving messages. Each bridge will result in a new `TokenManager` with a unique `tokenId`. There are a few different options that deployers have to obtain different kinds of `TokenManagers` with different guarantees and flexibility.

Note that a lot of the design choises were made with supporting non-EVM chains in mind.

### Canonical Bridges

Most current bridge designs aim to get a pre-existing, popular token to different chains that can benefit from the liquidity. When they do so the resulting token, called [`InterchainToken`](./contracts/utils/InterchainToken.sol) in this project, will only have basic functionality that enables users to transfer their token and use it with general use smart contracts like De-Fi applications. This is certainly powerful, and has the benefit that as long as the pre-existing `ERC20` implementation and the bridge function properly everything run as expected. We wanted to include this design for the `InterchainTokenService` as well, so deployers can deploy a Canonical Bridge for any token they want, and this can be done only once per pre-existing `ERC20`. Who the deployer is does not matter for this, they just need to pay for the deployment gas, but they do not need to be trusted as they have no special powers over this kind of bridge

### Custom Bridges

Most projects that look to go interchain nowadays have more complex needs that the ones covered by Canonical Bridges: they often need custom `ERC20` designs, and will sometimes want to have additional power over the bridge. This is where the `InterchainTokenService` shines, deployers can claim certain `tokenIds` only based on their `address`, and a `salt` they provide, and specify any kind of `TokenManager` to be deployed and either manage an external `ERC20` or a `InterchainToken`. Users using Custom Bridges need to trust the deployers as they could easily confiscate the funds of users if they wanted to, same as any `ERC20` minter could confiscate the funds of users. There are currently three kinds of possible `TokenManagers` available, but this number might increase in the future, as we find more potential uses for the `InterchainTokenService`.

-   Lock/Unlock: This `TokenManager` will simply transfer tokens from a user to itself or vice versa to initiate/fulfill interchain transfers
-   Mint/Burn: This `TokenManager` will burn/mint tokens from/to the user to initiate/fulfill interchain transfers. Tokens used with this kind of `TokenManager` need to be properly permissioned to allow for this behavior.

## Interchain Address Tracker

`InterchainTokenService` inherits the [`InterchainAddressTracker`](https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/main/contracts/utils/InterchainAddressTracker.sol) to support new chains as they get added to the Axelar Network. It's implemented for obtaining the destination address for outgoing messages, and for validation of incoming messages.

## Interchain Token

We designed an [interface](./contracts/interfaces/IInterchainToken.sol) along a [example implementation](./contracts/interchainToken/InterchainToken.sol) of an ERC20 that can use the `InterchainTokenService` internally. This has the main benefit that for `TokenManagers` that require user approval (Lock/Unlock typically) the token can provide this approval within the same call, providing better UX for users, and saving them some gas.
