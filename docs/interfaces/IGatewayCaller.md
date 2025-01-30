# Solidity API

## IGatewayCaller

_Interface for the GatewayCaller contract_

### MetadataVersion

_Enum representing different metadata versions_

```solidity
enum MetadataVersion {
  CONTRACT_CALL,
  EXPRESS_CALL
}
```

### InvalidMetadataVersion

```solidity
error InvalidMetadataVersion(uint32 metadataVersion)
```

_Error thrown when an invalid metadata version is provided_

### callContract

```solidity
function callContract(string destinationChain, string destinationAddress, bytes payload, enum IGatewayCaller.MetadataVersion metadataVersion, uint256 gasValue) external payable
```

Call the Axelar gateway to send a payload to a destination contract on a specific destination chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The target chain where the contract will be called |
| destinationAddress | string | The address of the contract to be called on the destination chain |
| payload | bytes | The data payload for the transaction |
| metadataVersion | enum IGatewayCaller.MetadataVersion | The version of metadata to be used |
| gasValue | uint256 | The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue. |

