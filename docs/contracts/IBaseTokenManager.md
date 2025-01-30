## IBaseTokenManager

This contract is defines the base token manager interface implemented by all token managers.

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32)
```

A function that returns the token id.

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

A function that should return the address of the token.
Must be overridden in the inheriting contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address address of the token. |

### getTokenAddressFromParams

```solidity
function getTokenAddressFromParams(bytes params) external pure returns (address)
```

A function that should return the token address from the init params.
