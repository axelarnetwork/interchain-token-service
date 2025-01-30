# Solidity API

## IInterchainTokenExpressExecutable

Contracts should implement this interface to accept express calls from the InterchainTokenService.

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

Executes express logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id for the call. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens to be transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the express execution. |

