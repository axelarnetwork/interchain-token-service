# Solidity API

## InterchainTokenService

This contract is responsible for facilitating interchain token transfers.
It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for interchain transfers to happen.

_The only storage used in this contract is for Express calls.
Furthermore, no ether is intended to or should be sent to this contract except as part of deploy/interchainTransfer payable methods for gas payment._

### gateway

```solidity
contract IAxelarGateway gateway
```

_There are two types of Axelar Gateways for cross-chain messaging:
1. Cross-chain messaging (GMP): The Axelar Gateway allows sending cross-chain messages.
   This is compatible across both Amplifier and consensus chains. IAxelarGateway interface exposes this functionality.
2. Cross-chain messaging with Gateway Token: The AxelarGateway on legacy consensus EVM connections supports this (via callContractWithToken)
   but not Amplifier chains. The gateway is cast to IAxelarGatewayWithToken when gateway tokens need to be handled.
   ITS deployments on Amplifier chains will revert when this functionality is used._

### gasService

```solidity
contract IAxelarGasService gasService
```

### interchainTokenFactory

```solidity
address interchainTokenFactory
```

Returns the address of the interchain token factory.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### chainNameHash

```solidity
bytes32 chainNameHash
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### interchainTokenDeployer

```solidity
address interchainTokenDeployer
```

Returns the address of the interchain token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenManagerDeployer

```solidity
address tokenManagerDeployer
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenManager

```solidity
address tokenManager
```

_Token manager implementation addresses_

### tokenHandler

```solidity
address tokenHandler
```

Returns the address of TokenHandler implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### gatewayCaller

```solidity
address gatewayCaller
```

### PREFIX_INTERCHAIN_TOKEN_ID

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_ID
```

### PREFIX_INTERCHAIN_TOKEN_SALT

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_SALT
```

### TOKEN_FACTORY_DEPLOYER

```solidity
address TOKEN_FACTORY_DEPLOYER
```

_Tokens and token managers deployed via the Token Factory contract use a special deployer address.
This removes the dependency on the address the token factory was deployed too to be able to derive the same tokenId._

### LATEST_METADATA_VERSION

```solidity
uint32 LATEST_METADATA_VERSION
```

_Latest version of metadata that's supported._

### ITS_HUB_CHAIN_NAME

```solidity
string ITS_HUB_CHAIN_NAME
```

_Chain name where ITS Hub exists. This is used for routing ITS calls via ITS hub.
This is set as a constant, since the ITS Hub will exist on Axelar._

### ITS_HUB_CHAIN_NAME_HASH

```solidity
bytes32 ITS_HUB_CHAIN_NAME_HASH
```

### ITS_HUB_ROUTING_IDENTIFIER

```solidity
string ITS_HUB_ROUTING_IDENTIFIER
```

_Special identifier that the trusted address for a chain should be set to, which indicates if the ITS call
for that chain should be routed via the ITS hub._

### ITS_HUB_ROUTING_IDENTIFIER_HASH

```solidity
bytes32 ITS_HUB_ROUTING_IDENTIFIER_HASH
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address interchainTokenDeployer_, address gateway_, address gasService_, address interchainTokenFactory_, string chainName_, address tokenManagerImplementation_, address tokenHandler_, address gatewayCaller_) public
```

Constructor for the Interchain Token Service.

_All of the variables passed here are stored as immutable variables._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployer_ | address | The address of the TokenManagerDeployer. |
| interchainTokenDeployer_ | address | The address of the InterchainTokenDeployer. |
| gateway_ | address | The address of the AxelarGateway. |
| gasService_ | address | The address of the AxelarGasService. |
| interchainTokenFactory_ | address | The address of the InterchainTokenFactory. |
| chainName_ | string | The name of the chain that this contract is deployed on. |
| tokenManagerImplementation_ | address | The tokenManager implementation. |
| tokenHandler_ | address | The tokenHandler implementation. |
| gatewayCaller_ | address | The gatewayCaller implementation. |

### onlyRemoteService

```solidity
modifier onlyRemoteService(string sourceChain, string sourceAddress)
```

This modifier is used to ensure that only a remote InterchainTokenService can invoke the execute function.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | The source chain of the contract call. |
| sourceAddress | string | The source address that the call came from. |

### onlyTokenFactory

```solidity
modifier onlyTokenFactory()
```

This modifier is used to ensure that only a the token factory can call a function.

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id of this contract. |

### tokenManagerAddress

```solidity
function tokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_)
```

Calculates the address of a TokenManager from a specific tokenId.

_The TokenManager does not need to exist already._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The deployment address of the TokenManager. |

### deployedTokenManager

```solidity
function deployedTokenManager(bytes32 tokenId) public view returns (contract ITokenManager tokenManager_)
```

Returns the instance of ITokenManager from a specific tokenId.

_This function checks if a token manager contract exists at the address for the specified tokenId.
If no token manager is deployed for the tokenId, the function will revert with `TokenManagerDoesNotExist`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the deployed token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager_ | contract ITokenManager | The instance of ITokenManager associated with the specified tokenId. |

### registeredTokenAddress

```solidity
function registeredTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

_This function requires that a token manager is already deployed for the specified tokenId.
It will call `deployedTokenManager` to get the token manager and return the address of the associated token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the registered token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |

### interchainTokenAddress

```solidity
function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the interchain token associated with the given tokenId.

_The token does not need to exist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the interchain token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a link for a given deployer with a specified salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address of the TokenManager deployer. |
| salt | bytes32 | The salt that the deployer uses for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId that the custom TokenManager would get (or has gotten). |

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256) external view returns (address)
```

Getter function for TokenManager implementation. This will mainly be called by TokenManager proxies
to figure out their implementations.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | tokenManagerAddress The address of the TokenManager implementation. |

### registerTokenMetadata

```solidity
function registerTokenMetadata(address tokenAddress, uint256 gasValue) external payable
```

Registers metadata for a token on the ITS Hub. This metadata is used for scaling linked tokens.
The token metadata must be registered before linkToken can be called for the corresponding token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |
| gasValue | uint256 | The cross-chain gas value for sending the registration message to ITS Hub. |

### registerCustomToken

```solidity
function registerCustomToken(bytes32 salt, address tokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes linkParams) external payable returns (bytes32 tokenId)
```

Only to be used by the InterchainTokenFactory to register custom tokens to this chain. Then link token can be used to register those tokens to other chains.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | A unique salt to derive tokenId from. |
| tokenAddress | address |  |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to use for the token registration. |
| linkParams | bytes | The operator for the token. |

### linkToken

```solidity
function linkToken(bytes32 salt, string destinationChain, bytes destinationTokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes linkParams, uint256 gasValue) public payable returns (bytes32 tokenId)
```

If `destinationChain` is an empty string, this function will register the token address on the current chain.
Otherwise, it will link the token address on the destination chain with the token corresponding to the tokenId on the current chain.
A token manager is deployed on EVM chains that's responsible for managing the linked token.

_This function replaces the prior `deployTokenManager` function._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | A unique identifier to allow for multiple tokens registered per deployer. |
| destinationChain | string | The chain to link the token to. Pass an empty string for this chain. |
| destinationTokenAddress | bytes | The token address to link, as bytes. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to use to send and receive tokens. |
| linkParams | bytes | Additional parameteres to use to link the token. Fow not it is just the address of the operator. |
| gasValue | uint256 | Pass a non-zero value only for remote linking, which should be the gas to use to pay for the contract call. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId associated with the token manager. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string destinationChain, string name, string symbol, uint8 decimals, bytes minter, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Used to deploy an interchain token alongside a TokenManager in another chain.

_At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
part of a multicall involving multiple functions that could make remote contract calls.
If minter is empty bytes, no additional minter is set on the token, only ITS is allowed to mint.
If the token is being deployed on the current chain, minter should correspond to an EVM address (as bytes).
Otherwise, an encoding appropriate to the destination chain should be used._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt to be used during deployment. |
| destinationChain | string | The name of the destination chain to deploy to. |
| name | string | The name of the token to be deployed. |
| symbol | string | The symbol of the token to be deployed. |
| decimals | uint8 | The decimals of the token to be deployed. |
| minter | bytes | The address that will be able to mint and burn the deployed token. |
| gasValue | uint256 | The amount of native tokens to be used to pay for gas for the remote deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### contractCallValue

```solidity
function contractCallValue(string sourceChain, string sourceAddress, bytes payload) public view virtual returns (address, uint256)
```

Returns the amount of token that this call is worth.

_If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | The source chain. |
| sourceAddress | string | The source address on the source chain. |
| payload | bytes | The payload sent with the call. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The token address. |
| [1] | uint256 | uint256 The value the call is worth. |

### execute

```solidity
function execute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) external
```

Executes the cross-chain ITS message.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The chain where the transaction originates from. |
| sourceAddress | string | The address of the remote ITS where the transaction originates from. |
| payload | bytes | The encoded data payload for the transaction. |

### expressExecute

```solidity
function expressExecute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) public payable
```

Express executes operations based on the payload and selector.

_This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The chain where the transaction originates from. |
| sourceAddress | string | The address of the remote ITS where the transaction originates from. |
| payload | bytes | The encoded data payload for the transaction. |

### getExpressExecutor

```solidity
function getExpressExecutor(bytes32 commandId, string sourceChain, string sourceAddress, bytes32 payloadHash) external view returns (address expressExecutor)
```

Returns the express executor for a given command.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The commandId for the contractCall. |
| sourceChain | string | The source chain. |
| sourceAddress | string | The source address. |
| payloadHash | bytes32 | The hash of the payload. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| expressExecutor | address | The address of the express executor. |

### _expressExecute

```solidity
function _expressExecute(bytes32 commandId, string sourceChain, bytes payload) internal
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
interchainTransfer that matches the parameters passed here.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id of the transfer being expressed. |
| sourceChain | string | the name of the chain where the interchainTransfer originated from. |
| payload | bytes | the payload of the receive token |

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata, uint256 gasValue) external payable
```

Initiates an interchain transfer of a specified token to a destination chain.

_The function retrieves the TokenManager associated with the tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| metadata | bytes | Optional metadata for the transfer. The first 4 bytes is the metadata version. To call the `destinationAddress` as a contract with a payload, provide `bytes.concat(bytes4(0), payload)` as the metadata. The token will be transferred to the destination app contract before it is executed. |
| gasValue | uint256 |  |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit an interchain transfer for the given tokenId.

_Only callable by a token registered under a tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of token to give. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

### setFlowLimits

```solidity
function setFlowLimits(bytes32[] tokenIds, uint256[] flowLimits) external
```

Used to set a flow limit for a token manager that has the service as its operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIds | bytes32[] | An array of the tokenIds of the tokenManagers to set the flow limits of. |
| flowLimits | uint256[] | The flowLimits to set. |

### setTrustedAddress

```solidity
function setTrustedAddress(string chain, string address_) external
```

Used to set a trusted address for a chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | The chain to set the trusted address of. |
| address_ | string | The address to set as trusted. |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

Used to remove a trusted address for a chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | The chain to set the trusted address of. |

### setPauseStatus

```solidity
function setPauseStatus(bool paused) external
```

Allows the owner to pause/unpause the token service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | Boolean value representing whether to pause or unpause. |

### migrateInterchainToken

```solidity
function migrateInterchainToken(bytes32 tokenId) external
```

Allows the owner to migrate minter of native interchain tokens from ITS to the corresponding token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the registered token. |

### _setup

```solidity
function _setup(bytes params) internal
```

### _processInterchainTransferPayload

```solidity
function _processInterchainTransferPayload(bytes32 commandId, address expressExecutor, string sourceChain, bytes payload) internal
```

Processes the payload data for a send token call.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| expressExecutor | address | The address of the express executor. Equals `address(0)` if it wasn't expressed. |
| sourceChain | string | The chain where the transaction originates from. |
| payload | bytes | The encoded data payload to be processed. |

### _processLinkTokenPayload

```solidity
function _processLinkTokenPayload(bytes payload) internal
```

Processes a deploy token manager payload.

### _processDeployInterchainTokenPayload

```solidity
function _processDeployInterchainTokenPayload(bytes payload) internal
```

Processes a deploy interchain token manager payload.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payload | bytes | The encoded data payload to be processed. |

### _routeMessage

```solidity
function _routeMessage(string destinationChain, bytes payload, enum IGatewayCaller.MetadataVersion metadataVersion, uint256 gasValue) internal
```

Route the ITS message to the destination chain with the given payload

_This method also determines whether the ITS call should be routed via the ITS Hub.
If the `trustedAddress(destinationChain) == 'hub'`, then the call is wrapped and routed to the ITS Hub destination._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The target chain where the contract will be called. |
| payload | bytes | The data payload for the transaction. |
| metadataVersion | enum IGatewayCaller.MetadataVersion |  |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _callContract

```solidity
function _callContract(string destinationChain, string destinationAddress, bytes payload, enum IGatewayCaller.MetadataVersion metadataVersion, uint256 gasValue) internal
```

Calls a contract on a destination chain via the gateway caller.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The chain where the contract will be called. |
| destinationAddress | string | The address of the contract to call. |
| payload | bytes | The data payload for the transaction. |
| metadataVersion | enum IGatewayCaller.MetadataVersion | The version of the metadata. |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _getCallParams

```solidity
function _getCallParams(string destinationChain, bytes payload) internal view returns (string, string, bytes)
```

_Get the params for the cross-chain message, taking routing via ITS Hub into account._

### _execute

```solidity
function _execute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload, bytes32 payloadHash) internal
```

### _getMessageType

```solidity
function _getMessageType(bytes payload) internal pure returns (uint256 messageType)
```

### _getExecuteParams

```solidity
function _getExecuteParams(string sourceChain, bytes payload) internal view returns (uint256, string, bytes)
```

_Return the parameters for the execute call, taking routing via ITS Hub into account._

### _deployRemoteInterchainToken

```solidity
function _deployRemoteInterchainToken(bytes32 tokenId, string name, string symbol, uint8 decimals, bytes minter, string destinationChain, uint256 gasValue) internal
```

Deploys an interchain token on a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals of the token. |
| minter | bytes | The minter address for the token. |
| destinationChain | string | The destination chain where the token will be deployed. |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _deployTokenManager

```solidity
function _deployTokenManager(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, address tokenAddress, bytes operator) internal
```

Deploys a token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to be deployed. |
| tokenAddress | address | The address of the token to be managed. |
| operator | bytes | The operator of the token manager. |

### _getInterchainTokenSalt

```solidity
function _getInterchainTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt)
```

Computes the salt for an interchain token deployment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The computed salt for the token deployment. |

### _deployInterchainToken

```solidity
function _deployInterchainToken(bytes32 tokenId, bytes minterBytes, string name, string symbol, uint8 decimals) internal returns (address tokenAddress)
```

Deploys an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| minterBytes | bytes | The minter address for the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals of the token. |

### _decodeMetadata

```solidity
function _decodeMetadata(bytes metadata) internal pure returns (enum IGatewayCaller.MetadataVersion version, bytes data)
```

Decodes the metadata into a version number and data bytes.

_The function expects the metadata to have the version in the first 4 bytes, followed by the actual data._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadata | bytes | The bytes containing the metadata to decode. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| version | enum IGatewayCaller.MetadataVersion | The version number extracted from the metadata. |
| data | bytes | The data bytes extracted from the metadata. |

### _transmitInterchainTransfer

```solidity
function _transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, enum IGatewayCaller.MetadataVersion metadataVersion, bytes data, uint256 gasValue) internal
```

Transmit a callContractWithInterchainToken for the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from, which will also be used for gas reimbursement. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of tokens to send. |
| metadataVersion | enum IGatewayCaller.MetadataVersion | The version of the metadata. |
| data | bytes | The data to be passed with the token transfer. |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _takeToken

```solidity
function _takeToken(bytes32 tokenId, address from, uint256 amount, bool tokenOnly) internal returns (uint256)
```

_Takes token from a sender via the token service. `tokenOnly` indicates if the caller should be restricted to the token only._

### _giveToken

```solidity
function _giveToken(bytes32 tokenId, address to, uint256 amount) internal returns (uint256, address tokenAddress)
```

_Gives token to recipient via the token service._

### _contractCallValue

```solidity
function _contractCallValue(bytes payload) internal view returns (address, uint256)
```

Returns the amount of token that this call is worth.

_If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payload | bytes | The payload sent with the call. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The token address. |
| [1] | uint256 | uint256 The value the call is worth. |

### _getExpressExecutorAndEmitEvent

```solidity
function _getExpressExecutorAndEmitEvent(bytes32 commandId, string sourceChain, string sourceAddress, bytes32 payloadHash) internal returns (address expressExecutor)
```

