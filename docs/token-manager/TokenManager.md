# Solidity API

## TokenManager

This contract is responsible for managing tokens, such as setting locking token balances, or setting flow limits, for interchain transfers.

### UINT256_MAX

```solidity
uint256 UINT256_MAX
```

### interchainTokenService

```solidity
address interchainTokenService
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

Constructs the TokenManager contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service. |

### onlyService

```solidity
modifier onlyService()
```

A modifier that allows only the interchain token service to execute the function.

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id. |

### tokenAddress

```solidity
function tokenAddress() external view virtual returns (address)
```

Reads the token address from the proxy.

_This function is not supported when directly called on the implementation. It
must be called by the proxy._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | tokenAddress_ The address of the token. |

### interchainTokenId

```solidity
function interchainTokenId() public pure returns (bytes32)
```

A function that returns the token id.

_This will only work when implementation is called by a proxy, which stores the tokenId as an immutable._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The interchain token ID. |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

Returns implementation type of this token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The implementation type of this token manager. |

### getTokenAddressFromParams

```solidity
function getTokenAddressFromParams(bytes params_) external pure returns (address tokenAddress_)
```

A function that should return the token address from the setup params.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The setup parameters. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The token address. |

### setup

```solidity
function setup(bytes params_) external
```

Setup function for the TokenManager.

_This function should only be called by the proxy, and only once from the proxy constructor.
The exact format of params depends on the type of TokenManager used but the first 32 bytes are reserved
for the address of the operator, stored as bytes (to be compatible with non-EVM chains)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The parameters to be used to initialize the TokenManager. |

### addFlowIn

```solidity
function addFlowIn(uint256 amount) external
```

### addFlowOut

```solidity
function addFlowOut(uint256 amount) external
```

### transferFlowLimiter

```solidity
function transferFlowLimiter(address from, address to) external
```

This function transfers a flow limiter for this TokenManager.

_Can only be called by the operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | the address of the old flow limiter. |
| to | address | the address of the new flow limiter. |

### addFlowLimiter

```solidity
function addFlowLimiter(address flowLimiter) external
```

This function adds a flow limiter for this TokenManager.

_Can only be called by the operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimiter | address | the address of the new flow limiter. |

### removeFlowLimiter

```solidity
function removeFlowLimiter(address flowLimiter) external
```

This function removes a flow limiter for this TokenManager.

_Can only be called by the operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimiter | address | the address of an existing flow limiter. |

### isFlowLimiter

```solidity
function isFlowLimiter(address addr) external view returns (bool)
```

Query if an address is a flow limiter.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is a flow limiter. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit_) external
```

This function sets the flow limit for this TokenManager.

_Can only be called by the flow limiters._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The maximum difference between the tokens flowing in and/or out at any given interval of time (6h). |

### approveService

```solidity
function approveService() external
```

A function to renew approval to the service if we need to.

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager.

_This function will be mainly used by frontends._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | The operator of the TokenManager. |
| tokenAddress_ | address | The token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The resulting params to be passed to custom TokenManager deployments. |

### mintToken

```solidity
function mintToken(address tokenAddress_, address to, uint256 amount) external
```

External function to allow the service to mint tokens through the tokenManager

_This function should revert if called by anyone but the service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the token, since its cheaper to pass it in instead of reading it as the token manager. |
| to | address | The recipient. |
| amount | uint256 | The amount to mint. |

### burnToken

```solidity
function burnToken(address tokenAddress_, address from, uint256 amount) external
```

External function to allow the service to burn tokens through the tokenManager

_This function should revert if called by anyone but the service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the token, since its cheaper to pass it in instead of reading it as the token manager. |
| from | address | The address to burn the token from. |
| amount | uint256 | The amount to burn. |

