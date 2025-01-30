# Solidity API

## IInterchainTokenFactory

This interface defines functions for deploying new interchain tokens and managing their token managers.

### ZeroAddress

```solidity
error ZeroAddress()
```

### InvalidChainName

```solidity
error InvalidChainName()
```

### InvalidMinter

```solidity
error InvalidMinter(address minter)
```

### NotMinter

```solidity
error NotMinter(address minter)
```

### NotSupported

```solidity
error NotSupported()
```

### RemoteDeploymentNotApproved

```solidity
error RemoteDeploymentNotApproved()
```

### InvalidTokenId

```solidity
error InvalidTokenId(bytes32 tokenId, bytes32 expectedTokenId)
```

### ZeroSupplyToken

```solidity
error ZeroSupplyToken()
```

### NotToken

```solidity
error NotToken(address tokenAddress)
```

### DeployRemoteInterchainTokenApproval

```solidity
event DeployRemoteInterchainTokenApproval(address minter, address deployer, bytes32 tokenId, string destinationChain, bytes destinationMinter)
```

Emitted when a minter approves a deployer for a remote interchain token deployment that uses a custom destinationMinter address.

### RevokedDeployRemoteInterchainTokenApproval

```solidity
event RevokedDeployRemoteInterchainTokenApproval(address minter, address deployer, bytes32 tokenId, string destinationChain)
```

Emitted when a minter revokes a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.

### interchainTokenService

```solidity
function interchainTokenService() external view returns (contract IInterchainTokenService)
```

Returns the address of the interchain token service.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract IInterchainTokenService | IInterchainTokenService The address of the interchain token service. |

### chainNameHash

```solidity
function chainNameHash() external view returns (bytes32)
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The hash of the chain name. |

### interchainTokenDeploySalt

```solidity
function interchainTokenDeploySalt(address deployer, bytes32 salt) external view returns (bytes32 deploySalt)
```

Computes the deploy salt for an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | A unique identifier to generate the salt. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The deploy salt for the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId)
```

Computes the ID for an interchain token based on the deployer and a salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address that deployed the interchain token. |
| salt | bytes32 | A unique identifier used in the deployment process. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the interchain token. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 initialSupply, address minter) external payable returns (bytes32 tokenId)
```

Deploys a new interchain token with specified parameters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals for the token. |
| initialSupply | uint256 | The amount of tokens to mint initially (can be zero), allocated to the msg.sender. |
| minter | address | The address to receive the initially minted tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### approveDeployRemoteInterchainToken

```solidity
function approveDeployRemoteInterchainToken(address deployer, bytes32 salt, string destinationChain, bytes destinationMinter) external
```

Allow the minter to approve the deployer for a remote interchain token deployment that uses a custom destinationMinter address.
This ensures that a token deployer can't choose the destinationMinter itself, and requires the approval of the minter to reduce trust assumptions on the deployer.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | The unique salt for deploying the token. |
| destinationChain | string | The name of the destination chain. |
| destinationMinter | bytes | The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes since the encoding of the account is dependent on the destination chain. |

### revokeDeployRemoteInterchainToken

```solidity
function revokeDeployRemoteInterchainToken(address deployer, bytes32 salt, string destinationChain) external
```

Allows the minter to revoke a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | The unique salt for deploying the token. |
| destinationChain | string | The name of the destination chain. |

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(bytes32 salt, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain. No additional minter is set on the deployed token.
Use the `deployRemoteInterchainTokenWithMinter` method to do so.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| destinationChain | string | The name of the destination chain. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainTokenWithMinter

```solidity
function deployRemoteInterchainTokenWithMinter(bytes32 salt, address minter, string destinationChain, bytes destinationMinter, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to distribute the token on the destination chain. |
| destinationChain | string | The name of the destination chain. |
| destinationMinter | bytes | The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes since the encoding of the account is dependent on the destination chain. If this is empty, then the `minter` of the token on the current chain is used as the destination minter, which makes it convenient when deploying to other EVM chains. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address minter, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deprecated: Use `deployRemoteInterchainToken` or `deployRemoteInterchainTokenWithMinter` instead.
Deploys a remote interchain token on a specified destination chain.

_originalChainName is only allowed to be '', i.e the current chain.
Other source chains are not supported anymore to simplify ITS token deployment behaviour._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChainName | string | The name of the chain where the token originally exists. |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to distribute the token on the destination chain. |
| destinationChain | string | The name of the destination chain. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### canonicalInterchainTokenDeploySalt

```solidity
function canonicalInterchainTokenDeploySalt(address tokenAddress) external view returns (bytes32 deploySalt)
```

Computes the deploy salt for a canonical interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The deploy salt for the interchain token. |

### canonicalInterchainTokenId

```solidity
function canonicalInterchainTokenId(address tokenAddress) external view returns (bytes32 tokenId)
```

Computes the ID for a canonical interchain token based on its address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the canonical interchain token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the canonical interchain token. |

### registerCanonicalInterchainToken

```solidity
function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Registers a canonical token as an interchain token and deploys its token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the canonical token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the registered canonical token. |

### deployRemoteCanonicalInterchainToken

```solidity
function deployRemoteCanonicalInterchainToken(address originalTokenAddress, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalTokenAddress | address | The address of the original token on the original chain. |
| destinationChain | string | The name of the chain where the token will be deployed. |
| gasValue | uint256 | The gas amount to be sent for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed canonical InterchainToken. |

### deployRemoteCanonicalInterchainToken

```solidity
function deployRemoteCanonicalInterchainToken(string originalChain, address originalTokenAddress, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.
This method is deprecated and will be removed in the future. Please use the above method instead.

_originalChain is only allowed to be '', i.e the current chain.
Other source chains are not supported anymore to simplify ITS token deployment behaviour._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChain | string | The name of the chain where the token originally exists. |
| originalTokenAddress | address | The address of the original token on the original chain. |
| destinationChain | string | The name of the chain where the token will be deployed. |
| gasValue | uint256 | The gas amount to be sent for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### linkedTokenDeploySalt

```solidity
function linkedTokenDeploySalt(address deployer, bytes32 salt) external view returns (bytes32 deploySalt)
```

Computes the deploy salt for a linked interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | The unique salt for deploying the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The deploy salt for the interchain token. |

### linkedTokenId

```solidity
function linkedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId)
```

Computes the ID for a linked token based on its address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | The unique salt for deploying the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the linked token. |

### registerCustomToken

```solidity
function registerCustomToken(bytes32 salt, address tokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, address operator) external payable returns (bytes32 tokenId)
```

Register an existing ERC20 token under a `tokenId` computed from the provided `salt`.
The token metadata must have been registered for tokens on each chain via `InterchainTokenService.registerTokenMetadata`.
This token can then be linked to remote tokens on different chains by submitting the `linkToken` function from the same `msg.sender` and using the same `salt`.

_This function is marked as payable since it can be called within a multicall with other payable methods._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId. |
| tokenAddress | address | The token address of the token being registered. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The token manager type used for the token link. |
| operator | address | The operator of the token manager. |

### linkToken

```solidity
function linkToken(bytes32 salt, string destinationChain, bytes destinationTokenAddress, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes linkParams, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Links a remote token on `destinationChain` to a local token corresponding to the `tokenId` computed from the provided `salt`.
A local token must have been registered first using the `registerCustomToken` function.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId. |
| destinationChain | string | The name of the destination chain. |
| destinationTokenAddress | bytes | The token address of the token being linked. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The token manager type used for the token link. |
| linkParams | bytes | Additional parameters for the token link depending on the destination chain. For EVM destination chains, this is an optional custom operator address. |
| gasValue | uint256 | The cross-chain gas value used to link the token on the destination chain. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the linked token. |

