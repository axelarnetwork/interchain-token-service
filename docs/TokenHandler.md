# Solidity API

## TokenHandler

This contract is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.

### giveToken

```solidity
function giveToken(bytes32 tokenId, address to, uint256 amount) external returns (uint256, address)
```

This function gives token to a specified address from the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The token id of the tokenManager. |
| to | address | The address to give tokens to. |
| amount | uint256 | The amount of tokens to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually given, which could be different for certain token type. |
| [1] | address | address the address of the token. |

### takeToken

```solidity
function takeToken(bytes32 tokenId, bool tokenOnly, address from, uint256 amount) external payable returns (uint256)
```

This function takes token from a specified address to the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId for the token. |
| tokenOnly | bool | can only be called from the token. |
| from | address | The address to take tokens from. |
| amount | uint256 | The amount of token to take. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually taken, which could be different for certain token type. |

### transferTokenFrom

```solidity
function transferTokenFrom(bytes32 tokenId, address from, address to, uint256 amount) external returns (uint256, address)
```

This function transfers token from and to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The token id of the token manager. |
| from | address | The address to transfer tokens from. |
| to | address | The address to transfer tokens to. |
| amount | uint256 | The amount of token to transfer. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually transferred, which could be different for certain token type. |
| [1] | address | address The address of the token corresponding to the input tokenId. |

### postTokenManagerDeploy

```solidity
function postTokenManagerDeploy(uint256 tokenManagerType, contract ITokenManager tokenManager) external payable
```

This function prepares a token manager after it is deployed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenManager | contract ITokenManager | The address of the token manager. |

### _transferTokenFrom

```solidity
function _transferTokenFrom(address tokenAddress, address from, address to, uint256 amount) internal
```

### _transferTokenFromWithFee

```solidity
function _transferTokenFromWithFee(address tokenAddress, address from, address to, uint256 amount) internal returns (uint256)
```

### _mintToken

```solidity
function _mintToken(contract ITokenManager tokenManager, address tokenAddress, address to, uint256 amount) internal
```

### _burnToken

```solidity
function _burnToken(contract ITokenManager tokenManager, address tokenAddress, address from, uint256 amount) internal
```

### _burnTokenFrom

```solidity
function _burnTokenFrom(address tokenAddress, address from, uint256 amount) internal
```

### _migrateToken

```solidity
function _migrateToken(address tokenManager, address tokenAddress, uint256 tokenManagerType) internal
```

This transfers mintership of a native Interchain token to the tokenManager if ITS is still its minter.
It does nothing if ITS is not the minter. This ensures that interchain tokens are auto-migrated without requiring a downtime for ITS.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager | address | The token manager address to transfer mintership to. |
| tokenAddress | address | The address of the token to transfer mintership of. |
| tokenManagerType | uint256 | The token manager type for the token. |

