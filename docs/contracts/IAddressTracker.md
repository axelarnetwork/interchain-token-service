## IAddressTracker

This interface allows setting and removing a trusted address for a specific chain.

_Extends the IInterchainAddressTracker interface._

### setTrustedAddress

```solidity
function setTrustedAddress(string chain, string address_) external
```

Sets the trusted address for the specified chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name to be trusted. |
| address_ | string | Trusted address to be added for the chain. |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

Remove the trusted address of the chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name to remove the trusted address for. |
