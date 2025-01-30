# Solidity API

## InterchainTokenStandard

The is an abstract contract that needs to be extended with an ERC20 implementation. See `InterchainToken` for an example implementation.

### interchainTokenId

```solidity
function interchainTokenId() public view virtual returns (bytes32 tokenId_)
```

Getter for the tokenId used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId_ | bytes32 | The tokenId that this token is registerred under. |

### interchainTokenService

```solidity
function interchainTokenService() public view virtual returns (address service)
```

Getter for the interchain token service.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| service | address | The address of the interchain token service. |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | The string representation of the destination chain. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer. |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address from, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) internal virtual
```

A method to be overwritten that will be called before an interchain transfer. One can approve the tokenManager here if needed,
to allow users for a 1-call transfer in case of a lock-unlock token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | The string representation of the destination chain. |
| destinationAddress | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer. |

### _spendAllowance

```solidity
function _spendAllowance(address sender, address spender, uint256 amount) internal virtual
```

A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.

_Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient._

