# Solidity API

## ITokenManagerImplementation

Interface for returning the token manager implementation type.

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress_)
```

Returns the implementation address for a given token manager type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The type of token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager implementation. |

