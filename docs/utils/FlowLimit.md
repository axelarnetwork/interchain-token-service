# Solidity API

## FlowLimit

Implements flow limit logic for interchain token transfers.

_This contract implements low-level assembly for optimization purposes._

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
function _setFlowLimit(uint256 flowLimit_, bytes32 tokenId) internal
```

Internal function to set the flow limit.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The value to set the flow limit to. |
| tokenId | bytes32 | The id of the token to set the flow limit for. |

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

Returns the slot which is used to get the flow out amount for a specific epoch.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow out amount for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow out amount from. |

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow in amount for a specific epoch._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow in amount for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow in amount from. |

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

Adds a flow amount while ensuring it does not exceed the flow limit.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |
| slotToAdd | uint256 | The slot to add the flow to. |
| slotToCompare | uint256 | The slot to compare the flow against. |
| flowAmount | uint256 | The flow amount to add. |

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount_) internal
```

Adds a flow out amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The flow out amount to add. |

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount_) internal
```

Adds a flow in amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The flow in amount to add. |

