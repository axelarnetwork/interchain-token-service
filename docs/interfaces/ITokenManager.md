# Solidity API

## ITokenManager

This contract is responsible for managing tokens, such as setting locking token balances, or setting flow limits, for interchain transfers.

### TokenLinkerZeroAddress

```solidity
error TokenLinkerZeroAddress()
```

### NotService

```solidity
error NotService(address caller)
```

### TakeTokenFailed

```solidity
error TakeTokenFailed()
```

### GiveTokenFailed

```solidity
error GiveTokenFailed()
```

### NotToken

```solidity
error NotToken(address caller)
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### AlreadyFlowLimiter

```solidity
error AlreadyFlowLimiter(address flowLimiter)
```

### NotFlowLimiter

```solidity
error NotFlowLimiter(address flowLimiter)
```

### NotSupported

```solidity
error NotSupported()
```

### implementationType

```solidity
function implementationType() external view returns (uint256)
```

Returns implementation type of this token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The implementation type of this token manager. |

### addFlowIn

```solidity
function addFlowIn(uint256 amount) external
```

### addFlowOut

```solidity
function addFlowOut(uint256 amount) external
```

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

