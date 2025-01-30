# Solidity API

## IInterchainTokenExecutable

Contracts should implement this interface to accept calls from the InterchainTokenService.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

This will be called after the tokens are sent to this contract.

_Execution should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id for the call. |
| sourceChain | string | The name of the source chain. |
| sourceAddress | bytes | The address that sent the contract call. |
| data | bytes | The data to be processed. |
| tokenId | bytes32 | The tokenId of the token manager managing the token. |
| token | address | The address of the token. |
| amount | uint256 | The amount of tokens that were sent. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the execution. |

