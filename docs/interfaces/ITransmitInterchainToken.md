# Solidity API

## ITransmitInterchainToken

Interface for transmiting interchain tokens via the interchain token service

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit an interchain transfer for the given tokenId.

_Only callable by a token registered under a tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of token to give. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

