# Solidity API

## IInterchainTokenStandard

_Interface of the ERC20 standard as defined in the EIP._

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method.

_We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

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
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract.) |

