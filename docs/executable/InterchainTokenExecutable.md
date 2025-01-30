# Solidity API

## InterchainTokenExecutable

Abstract contract that defines an interface for executing arbitrary logic
in the context of interchain token operations.

_This contract should be inherited by contracts that intend to execute custom
logic in response to interchain token actions such as transfers. This contract
will only be called by the interchain token service._

### NotService

```solidity
error NotService(address caller)
```

### interchainTokenService

```solidity
address interchainTokenService
```

### EXECUTE_SUCCESS

```solidity
bytes32 EXECUTE_SUCCESS
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

Creates a new InterchainTokenExecutable contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service that will call this contract. |

### onlyService

```solidity
modifier onlyService()
```

Modifier to restrict function execution to the interchain token service.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

Executes logic in the context of an interchain token transfer.

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
| amount | uint256 | The amount of tokens being transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the execution. |

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal virtual
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

