# Solidity API

## TestFlowLimitLiveNetwork

### FLOW_LIMIT_SLOT

```solidity
uint256 FLOW_LIMIT_SLOT
```

### PREFIX_FLOW_OUT_AMOUNT

```solidity
uint256 PREFIX_FLOW_OUT_AMOUNT
```

### PREFIX_FLOW_IN_AMOUNT

```solidity
uint256 PREFIX_FLOW_IN_AMOUNT
```

### TOKEN_ID

```solidity
bytes32 TOKEN_ID
```

### EPOCH_TIME

```solidity
uint256 EPOCH_TIME
```

### flowLimit

```solidity
function flowLimit() public view returns (uint256 flowLimit_)
```

Returns the current flow limit.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |

### _setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit_) internal
```

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

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

### _addFlow

```solidity
function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount_) internal
```

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount_) internal
```

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit_) external
```

### addFlowIn

```solidity
function addFlowIn(uint256 flowInAmount_) external
```

### addFlowOut

```solidity
function addFlowOut(uint256 flowOutAmount_) external
```

