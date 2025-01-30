# Solidity API

## IFlowLimit

Interface for flow limit logic for interchain token transfers.

### FlowLimitExceeded

```solidity
error FlowLimitExceeded(uint256 limit, uint256 flowAmount, address tokenManager)
```

### FlowAdditionOverflow

```solidity
error FlowAdditionOverflow(uint256 flowAmount, uint256 flowToAdd, address tokenManager)
```

### FlowLimitOverflow

```solidity
error FlowLimitOverflow(uint256 flowLimit, uint256 flowToCompare, address tokenManager)
```

### FlowLimitSet

```solidity
event FlowLimitSet(bytes32 tokenId, address operator, uint256 flowLimit_)
```

### flowLimit

```solidity
function flowLimit() external view returns (uint256 flowLimit_)
```

Returns the current flow limit.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount. |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount. |

