# Solidity API

## Operator

A contract module which provides a basic access control mechanism, where
there is an account (a operator) that can be granted exclusive access to
specific functions.

_This module is used through inheritance._

### _addOperator

```solidity
function _addOperator(address operator) internal
```

Internal function that stores the new operator address in the correct storage slot

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator |

### transferOperatorship

```solidity
function transferOperatorship(address operator) external
```

Change the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator. |

### proposeOperatorship

```solidity
function proposeOperatorship(address operator) external
```

Propose a change of the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator. |

### acceptOperatorship

```solidity
function acceptOperatorship(address fromOperator) external
```

Accept a proposed change of operatorship.

_Can only be called by the proposed operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromOperator | address | The previous operator of the contract. |

### isOperator

```solidity
function isOperator(address addr) external view returns (bool)
```

Query if an address is a operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is an operator. |

