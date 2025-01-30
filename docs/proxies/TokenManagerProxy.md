# Solidity API

## TokenManagerProxy

This contract is a proxy for token manager contracts.

_This contract implements BaseProxy and ITokenManagerProxy._

### interchainTokenService

```solidity
address interchainTokenService
```

### implementationType

```solidity
uint256 implementationType
```

Returns implementation type of this token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### interchainTokenId

```solidity
bytes32 interchainTokenId
```

Returns the interchain token ID of the token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenAddress

```solidity
address tokenAddress
```

Returns token address that this token manager manages.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor(address interchainTokenService_, uint256 implementationType_, bytes32 tokenId, bytes params) public
```

Constructs the TokenManagerProxy contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service. |
| implementationType_ | uint256 | The token manager type. |
| tokenId | bytes32 | The identifier for the token. |
| params | bytes | The initialization parameters for the token manager contract. |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id. |

### getImplementationTypeAndTokenAddress

```solidity
function getImplementationTypeAndTokenAddress() external view returns (uint256 implementationType_, address tokenAddress_)
```

Returns implementation type and token address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationType_ | uint256 | The implementation type. |
| tokenAddress_ | address | The token address. |

### implementation

```solidity
function implementation() public view returns (address implementation_)
```

Returns the address of the current implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The address of the current implementation. |

### _tokenManagerImplementation

```solidity
function _tokenManagerImplementation(address interchainTokenService_, uint256 implementationType_) internal view returns (address implementation_)
```

Returns the implementation address from the interchain token service for the provided type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service. |
| implementationType_ | uint256 | The token manager type. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementation_ | address | The address of the implementation. |

