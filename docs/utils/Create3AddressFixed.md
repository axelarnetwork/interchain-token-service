# Solidity API

## Create3AddressFixed

This contract can be used to predict the deterministic deployment address of a contract deployed with the `CREATE3` technique.
It is equivalent to the Create3Address found in axelar-gmp-sdk-solidity repo but uses a fixed bytecode for CreateDeploy,
which allows changing compilation options (like number of runs) without affecting the future deployment addresses.

### CREATE_DEPLOY_BYTECODE

```solidity
bytes CREATE_DEPLOY_BYTECODE
```

### CREATE_DEPLOY_BYTECODE_HASH

```solidity
bytes32 CREATE_DEPLOY_BYTECODE_HASH
```

### _create3Address

```solidity
function _create3Address(bytes32 deploySalt) internal view returns (address deployed)
```

Compute the deployed address that will result from the `CREATE3` method.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | A salt to influence the contract address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployed | address | The deterministic contract address if it was deployed |

