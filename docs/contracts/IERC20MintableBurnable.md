## IERC20MintableBurnable

_Interface of the ERC20 standard as defined in the EIP._

### mint

```solidity
function mint(address to, uint256 amount) external
```

Function to mint new tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address that will receive the minted tokens. |
| amount | uint256 | The amount of tokens to mint. |

### burn

```solidity
function burn(address from, uint256 amount) external
```

Function to burn tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt. |
| amount | uint256 | The amount of tokens to burn. |
