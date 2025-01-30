# Solidity API

## IInterchainTokenService

Interface for the Interchain Token Service

### InvalidChainName

```solidity
error InvalidChainName()
```

### NotRemoteService

```solidity
error NotRemoteService()
```

### TokenManagerDoesNotExist

```solidity
error TokenManagerDoesNotExist(bytes32 tokenId)
```

### ExecuteWithInterchainTokenFailed

```solidity
error ExecuteWithInterchainTokenFailed(address contractAddress)
```

### ExpressExecuteWithInterchainTokenFailed

```solidity
error ExpressExecuteWithInterchainTokenFailed(address contractAddress)
```

### TokenManagerDeploymentFailed

```solidity
error TokenManagerDeploymentFailed(bytes error)
```

### InterchainTokenDeploymentFailed

```solidity
error InterchainTokenDeploymentFailed(bytes error)
```

### InvalidMessageType

```solidity
error InvalidMessageType(uint256 messageType)
```

### InvalidMetadataVersion

```solidity
error InvalidMetadataVersion(uint32 version)
```

### InvalidExpressMessageType

```solidity
error InvalidExpressMessageType(uint256 messageType)
```

### TakeTokenFailed

```solidity
error TakeTokenFailed(bytes data)
```

### GiveTokenFailed

```solidity
error GiveTokenFailed(bytes data)
```

### TokenHandlerFailed

```solidity
error TokenHandlerFailed(bytes data)
```

### EmptyData

```solidity
error EmptyData()
```

### PostDeployFailed

```solidity
error PostDeployFailed(bytes data)
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### CannotDeploy

```solidity
error CannotDeploy(enum ITokenManagerType.TokenManagerType)
```

### CannotDeployRemotelyToSelf

```solidity
error CannotDeployRemotelyToSelf()
```

### InvalidPayload

```solidity
error InvalidPayload()
```

### GatewayCallFailed

```solidity
error GatewayCallFailed(bytes data)
```

### EmptyTokenName

```solidity
error EmptyTokenName()
```

### EmptyTokenSymbol

```solidity
error EmptyTokenSymbol()
```

### EmptyParams

```solidity
error EmptyParams()
```

### EmptyDestinationAddress

```solidity
error EmptyDestinationAddress()
```

### EmptyTokenAddress

```solidity
error EmptyTokenAddress()
```

### NotSupported

```solidity
error NotSupported()
```

### NotInterchainTokenFactory

```solidity
error NotInterchainTokenFactory(address sender)
```

### InterchainTransfer

```solidity
event InterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes32 dataHash)
```

### InterchainTransferReceived

```solidity
event InterchainTransferReceived(bytes32 commandId, bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes32 dataHash)
```

### TokenMetadataRegistered

```solidity
event TokenMetadataRegistered(address tokenAddress, uint8 decimals)
```

### LinkTokenStarted

```solidity
event LinkTokenStarted(bytes32 tokenId, string destinationChain, bytes sourceTokenAddress, bytes destinationTokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeploymentStarted

```solidity
event InterchainTokenDeploymentStarted(bytes32 tokenId, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes minter, string destinationChain)
```

### TokenManagerDeployed

```solidity
event TokenManagerDeployed(bytes32 tokenId, address tokenManager, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeployed

```solidity
event InterchainTokenDeployed(bytes32 tokenId, address tokenAddress, address minter, string name, string symbol, uint8 decimals)
```

### InterchainTokenIdClaimed

```solidity
event InterchainTokenIdClaimed(bytes32 tokenId, address deployer, bytes32 salt)
```

### tokenManagerDeployer

```solidity
function tokenManagerDeployer() external view returns (address tokenManagerDeployerAddress)
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployerAddress | address | The address of the token manager deployer contract. |

### interchainTokenDeployer

```solidity
function interchainTokenDeployer() external view returns (address interchainTokenDeployerAddress)
```

Returns the address of the interchain token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenDeployerAddress | address | The address of the interchain token deployer contract. |

### tokenManager

```solidity
function tokenManager() external view returns (address tokenManagerAddress_)
```

Returns the address of TokenManager implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager contract. |

### tokenHandler

```solidity
function tokenHandler() external view returns (address tokenHandlerAddress)
```

Returns the address of TokenHandler implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenHandlerAddress | address | The address of the token handler contract. |

### interchainTokenFactory

```solidity
function interchainTokenFactory() external view returns (address)
```

Returns the address of the interchain token factory.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The address of the interchain token factory. |

### chainNameHash

```solidity
function chainNameHash() external view returns (bytes32)
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The hash of the chain name. |

### tokenManagerAddress

```solidity
function tokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress_)
```

Returns the address of the token manager associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager. |

### deployedTokenManager

```solidity
function deployedTokenManager(bytes32 tokenId) external view returns (contract ITokenManager tokenManager_)
```

Returns the instance of ITokenManager from a specific tokenId.

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
function registeredTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

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
function interchainTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the interchain token associated with the given tokenId.

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
function interchainTokenId(address operator_, bytes32 salt) external view returns (bytes32 tokenId)
```

Returns the custom tokenId associated with the given operator and salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The operator address. |
| salt | bytes32 | The salt used for token id calculation. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The custom tokenId associated with the operator and salt. |

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
function linkToken(bytes32 salt, string destinationChain, bytes destinationTokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes linkParams, uint256 gasValue) external payable returns (bytes32 tokenId)
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

Deploys and registers an interchain token on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used for token deployment. |
| destinationChain | string | The name of the destination chain. Use '' for this chain. |
| name | string | The name of the interchain tokens. |
| symbol | string | The symbol of the interchain tokens. |
| decimals | uint8 | The number of decimals for the interchain tokens. |
| minter | bytes | The minter data for mint/burn operations. |
| gasValue | uint256 | The gas value for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata, uint256 gasValue) external payable
```

Initiates an interchain transfer of a specified token to a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |
| gasValue | uint256 |  |

### setFlowLimits

```solidity
function setFlowLimits(bytes32[] tokenIds, uint256[] flowLimits) external
```

Sets the flow limits for multiple tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIds | bytes32[] | An array of tokenIds. |
| flowLimits | uint256[] | An array of flow limits corresponding to the tokenIds. |

### setPauseStatus

```solidity
function setPauseStatus(bool paused) external
```

Allows the owner to pause/unpause the token service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | whether to pause or unpause. |

### migrateInterchainToken

```solidity
function migrateInterchainToken(bytes32 tokenId) external
```

Allows the owner to migrate legacy tokens that cannot be migrated automatically.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the registered token. |

