# Solidity API

## IERC20BurnableFrom

Interface of the ERC20 standard as defined in the EIP.

### burnFrom

```solidity
function burnFrom(address from, uint256 amount) external
```

Function to burn tokens.

_Requires the caller to have allowance for `amount` on `from`.
Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt. |
| amount | uint256 | The amount of tokens to burn. |

