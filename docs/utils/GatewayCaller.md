# Solidity API

## GatewayCaller

_This contract is used to handle cross-chain ITS calls via the Axelar gateway._

### gateway

```solidity
contract IAxelarGateway gateway
```

### gasService

```solidity
contract IAxelarGasService gasService
```

### constructor

```solidity
constructor(address gateway_, address gasService_) public
```

_Constructor to initialize the GatewayCaller contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| gateway_ | address | The address of the AxelarGateway contract |
| gasService_ | address | The address of the AxelarGasService contract |

### callContract

```solidity
function callContract(string destinationChain, string destinationAddress, bytes payload, enum IGatewayCaller.MetadataVersion metadataVersion, uint256 gasValue) external payable
```

_Calls a contract on a specific destination chain with the given payload_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The target chain where the contract will be called |
| destinationAddress | string | The address of the contract to be called on the destination chain |
| payload | bytes | The data payload for the transaction |
| metadataVersion | enum IGatewayCaller.MetadataVersion | The version of metadata to be used |
| gasValue | uint256 | The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue. |

