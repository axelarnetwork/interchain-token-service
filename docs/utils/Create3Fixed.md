# Solidity API

## Create3Fixed

This contract can be used to deploy a contract with a deterministic address that depends only on
the deployer address and deployment salt, not the contract bytecode and constructor parameters.
It uses a fixed bytecode to allow changing the compilation settings without affecting the deployment address in the future.

### _create3

```solidity
function _create3(bytes bytecode, bytes32 deploySalt) internal returns (address deployed)
```

Deploys a new contract using the `CREATE3` method.

_This function first deploys the CreateDeploy contract using
the `CREATE2` opcode and then utilizes the CreateDeploy to deploy the
new contract with the `CREATE` opcode._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| bytecode | bytes | The bytecode of the contract to be deployed |
| deploySalt | bytes32 | A salt to influence the contract address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployed | address | The address of the deployed contract |

