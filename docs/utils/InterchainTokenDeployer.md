# Solidity API

## InterchainTokenDeployer

This contract is used to deploy new instances of the InterchainTokenProxy contract.

### implementationAddress

```solidity
address implementationAddress
```

Returns the interchain token implementation address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor(address implementationAddress_) public
```

Constructor for the InterchainTokenDeployer contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress_ | address | Address of the InterchainToken contract. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, bytes32 tokenId, address minter, string name, string symbol, uint8 decimals) external returns (address tokenAddress)
```

Deploys a new instance of the InterchainTokenProxy contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used by Create3Deployer. |
| tokenId | bytes32 | TokenId for the token. |
| minter | address | Address of the minter. |
| name | string | Name of the token. |
| symbol | string | Symbol of the token. |
| decimals | uint8 | Decimals of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of the deployed token. |

### deployedAddress

```solidity
function deployedAddress(bytes32 salt) external view returns (address tokenAddress)
```

Returns the interchain token deployment address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The deployment salt. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The token address. |

