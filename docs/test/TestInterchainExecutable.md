# Solidity API

## TestInterchainExecutable

### MessageReceived

```solidity
event MessageReceived(bytes32 commandId, string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount)
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### lastMessage

```solidity
string lastMessage
```

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal
```

Internal function containing the logic to be executed with interchain token transfer.

_Logic must be implemented by derived contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens being transferred. |

