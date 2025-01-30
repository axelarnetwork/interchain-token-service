# Solidity API

## InterchainTokenExpressExecutable

Abstract contract that defines an interface for executing express logic in the context of interchain token operations.

_This contract extends `InterchainTokenExecutable` to provide express execution capabilities. It is intended to be inherited by contracts
that implement express logic for interchain token actions. This contract will only be called by the interchain token service._

### EXPRESS_EXECUTE_SUCCESS

```solidity
bytes32 EXPRESS_EXECUTE_SUCCESS
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

Creates a new InterchainTokenExpressExecutable contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service that will call this contract. |

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

Executes express logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
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

