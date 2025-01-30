# Solidity API

## ITokenManagerProxy

This interface is for a proxy for token manager contracts.

### ZeroAddress

```solidity
error ZeroAddress()
```

### implementationType

```solidity
function implementationType() external view returns (uint256)
```

Returns implementation type of this token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The implementation type of this token manager. |

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32)
```

Returns the interchain token ID of the token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The interchain token ID of the token manager. |

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

Returns token address that this token manager manages.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The token address. |

### getImplementationTypeAndTokenAddress

```solidity
function getImplementationTypeAndTokenAddress() external view returns (uint256, address)
```

Returns implementation type and token address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The implementation type. |
| [1] | address | address The token address. |

