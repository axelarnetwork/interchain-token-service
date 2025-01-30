# Solidity API

## IMinter

An interface for a contract module which provides a basic access control mechanism, where
there is an account (a minter) that can be granted exclusive access to specific functions.

### transferMintership

```solidity
function transferMintership(address minter_) external
```

Change the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### proposeMintership

```solidity
function proposeMintership(address minter_) external
```

Proposed a change of the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### acceptMintership

```solidity
function acceptMintership(address fromMinter) external
```

Accept a change of the minter of the contract.

_Can only be called by the proposed minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromMinter | address | The previous minter. |

### isMinter

```solidity
function isMinter(address addr) external view returns (bool)
```

Query if an address is a minter

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is a minter. |

