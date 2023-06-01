# Interchain Token

## Introduction

This repo will provide an implementation for an Interchain Token Service and an Interchain Token using it.

## Interchain Token Service

### Getters

`getOriginalChain(bytes32 tokenId) external view returns (string memory origin)`

- returns the name of the chain that the token was originally registered at.

`getTokenId(address tokenAddress) external view returns (bytes32 tokenId)`

- returns the `tokenId` of a token with a specified address (if registered)

`getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)`

- returns the `tokenAddress` of a registered token with a specified `tokenId`

`getOriginTokenId(address tokenAddress) external view returns (bytes32 tokenId)`

- returns the expected `tokenId` of an origin token that exists on chain with a specified `tokenAddress`. If the `tokenAddress` provided is one that exists and is a remote token then the `tokenId` output will be incorrect.

### Register and Deploy

`deployInterchainToken(
    string calldata tokenName,
    string calldata tokenSymbol,
    uint8 decimals,
    address owner,
    bytes32 salt,
    string[] calldata destinationChains,
    uint256[] calldata gasValues
) external payable;`

- Deploys an interchain token with the specified `tokenName`, `tokenSymbol` and `decimals`. Gives ownership of said token to `owner`, and uses `salt` (along with `msg.sender` to determine the `tokenAddress`.
    - reverts with `TokenDeploymentFailed()` if something goes wrong with tokenDeployment.
    - emits `TokenDeployed(...)`
- Registers the token in question.
    - emits `TokenRegistered(...)`
- Initiates remote deployments to `destiantionChains` using `gasValues` as gas payments of each.
    - reverts with `LengthMismatch()` if `destinationChains.length != gasValues.length`
    - emits `RemoteTokenRegisterInitialized(...)`

`registerOriginToken(address tokenAddress) external returns (bytes32 tokenId)`

- Registers an origin token with a specified `tokenAddress`.
    - emits `tokenRegistered(...)`.
    - reverts if `token` address does not support the `name()`, `symbol()` and `decimals()` methods with proper returns.
    - reverts with `AlreadyRegistered()` if the token is already registered.
    - reverts with `GatewayToken()` if the token is a gateway token.

`deployRemoteTokens(
    bytes32 tokenId, 
    string[] calldata destinationChains, 
    uint256[] calldata gasValues
) external payable`

- Initiates the deployment remote tokens for the registered token with `tokenId` to remote chains specified by `destinationChains`. Takes `sum(gasValues)` amount of native currency and uses it to pay for gas as specified by `gasValues` for each chain.
    - emits `RemoteTokenRegisterInitialized(...)` once for each specified chain.
    - reverts with `NotOriginToken()` if the `tokenId` does not exist or the token is not an origin token.
    - revers with `GatewayToken()` if the token specified is a gateway token and the Axelar Gateway supports tokens on any of the destination chains.
    - reverts with `LengthMismatch()` if `destinationChains.length != gasValues.length`.

`registerOriginTokenAndDeployRemoteTokens(
    address tokenAddress,
    string[] calldata destinationChains,
    uint256[] calldata gasValues
) external payable returns (bytes32 tokenId)`

- combines the two methods above into one.
    - emits `tokenRegistered(...)`.
    - reverts if `token` address does not support the `name()`, `symbol()` and `decimals()` methods with proper returns.
    - reverts with `AlreadyRegistered()` if the token is already registered.
    - reverts with `GatewayToken()` if the token is a gateway token.
    - emits `RemoteTokenRegisterInitialized(...)` once for each specified chain.
    - reverts with `LengthMismatch()` if `destinationChains.length != gasValues.length`.

### Send Tokens

`sendToken(bytes32 tokenId, string memory destinationChain, bytes memory to, uint256 amount) external payable`

- Sends a pre-approved `amount` of a registered token specified by `tokenId` to the `destinationChain`, the specified address `to`, and uses any native currency received to pay for gas.
    - emits `Sending(...)`
    - reverts with `NotRegistered()` if the token is not registered.
    - reverts with `TransferFromFailed()` when dealing with an origin token and calling `transferFrom(...)` to the token reverts.
    - reverts with `BurnFailed()` when dealing with a remote token and calling `burnFrom(...)` to the token reverts.

`function callContractWithInterToken(
    bytes32 tokenId,
    string memory destinationChain,
    bytes memory to,
    uint256 amount,
    bytes calldata data
) external payable`

- Same as above but also sends over `data` to be parsed at the destination chain.
    - emits `SendingWithData(...)`.
    - reverts with `NotRegistered()` if the token is not registered.
    - reverts with `TransferFromFailed()` when dealing with an origin token and calling `transferFrom(...)` to the token reverts.
    - reverts with `BurnFailed()` when dealing with a remote token and calling `burnFrom(...)` to the token reverts.

`function sendSelf(
    address from, 
    string memory destinationChain, 
    bytes memory to, 
    uint256 amount
) external payable`

- This is meant to be called by tokens to facilitate transfers
    - gets the `tokenId` for `tokenAddress == msg.sender`.
    - reverts with `notRegistered()` if `msg.sender` is not a registered token.
    - Takes token from `from` (either with `transferFrom` or with `burnFrom`).
    - emits `Sending(...)`.

`function callContractWithSelf(
    address from,
    string memory destinationChain,
    bytes memory to,
    uint256 amount,
    bytes calldata data
) external payable`

- This is also meant to be called by tokens to facilitate transfers with metadata.
    - gets the `tokenId` for `tokenAddress == msg.sender`.
    - reverts with `notRegistered()` if `msg.sender` is not a registered token.
    - Takes token from `from` (either with `transferFrom` or with `burnFrom`).
    - emits `SendingWithData(...)`.

### Receiving Calls

When receiving calls from a remote Interchain token Linker the following behaviour is expected. All the below names are not *real,* because the method called is simply `execute` which figures out what to do based on the payload.

`deployToken(...)`

- Deploys a remote token on this chain
    - emits `TokenDeployed(...)`.
    - reverts with `AlreadyRegistered()` if the token is already deployed.
    - emits `TokenRegistered(...)`.

`giveToken(...)`

- Gives (either transfers for origin tokens or mints for remote tokens) the appropriate amount of token the the address specified.
    - emits `Receiving(...)`.
    - reverts with `NotRegistered()` if the token is not registered on this chain (if it is not deployed beforehand).

`giveToken(...)`

- Gives (either transfers for origin tokens or mints for remote tokens) the appropriate amount of token the the address specified.
    - emits `Receiving(...)`.
    - reverts with `NotRegistered()` if the token is not registered on this chain (if it is not deployed beforehand).

`giveTokenWithData(...)`

- Gives (either transfers for origin tokens or mints for remote tokens) the appropriate amount of token the the address specified.
    - emits `ReceivingWithData(...)`.
    - reverts with `NotRegistered()` if the token is not registered on this chain (if it is not deployed beforehand).
    - calls `proccessToken(tokenId, amount)` of the destination address after transferring the token.

## Contract Design 

There are two nuances when it comes to the smart contract design, deploying potentially different contracts with to the same address, and differentiating between remote messages.

### Deploying potentially different contracts to the same address

This can in general easily be achieved by using [create3](https://github.com/axelarnetwork/axelar-gmp-sdk-solidity). However to do so we need to have access to the bytecode of the deployed contract at runtime, without having anyone pass it in. Loading it from storage would be way to costly, and the author of this has no idea if it is possible to store it in the bytecode of a the contract trying to do the deployment and accessing it at runtime (`immutable` variables do this, but they cannot have variable length and must be 32 bytes). To circumvent this we will use a contract that will have its entire bytecode be the deployment bytecode, which can be accesses by using `address.code` for a reasonable gas price.

### Differentiating between remote messages

Having multiple different commands be executed remotely is easily achievable but there are a few ways to go about it. Basically the payload will have to begin with a certain number of bytes that explain what the operation is. To do this we can either use 32 bytes, and `abi.decode(uing256)` to get only the selector, and have a large `if...else...else...then` section, or use the first 4 bytes as a solidity function selector and use different functions that can only be called by the contract itself. The second design is selected here as it is considered more elegant.
