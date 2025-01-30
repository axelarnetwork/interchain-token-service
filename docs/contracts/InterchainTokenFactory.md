## InterchainTokenFactory

This contract is responsible for deploying new interchain tokens and managing their token managers.

### INTERCHAIN_TOKEN_FACTORY_SLOT

```solidity
bytes32 INTERCHAIN_TOKEN_FACTORY_SLOT
```

_This slot contains the storage for this contract in an upgrade-compatible manner
keccak256('InterchainTokenFactory.Slot') - 1;_

### PREFIX_CANONICAL_TOKEN_SALT

```solidity
bytes32 PREFIX_CANONICAL_TOKEN_SALT
```

### PREFIX_INTERCHAIN_TOKEN_SALT

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_SALT
```

### PREFIX_DEPLOY_APPROVAL

```solidity
bytes32 PREFIX_DEPLOY_APPROVAL
```

### interchainTokenService

```solidity
contract IInterchainTokenService interchainTokenService
```

Returns the address of the interchain token service.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### chainNameHash

```solidity
bytes32 chainNameHash
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### DeployApproval

```solidity
struct DeployApproval {
  address minter;
  bytes32 tokenId;
  string destinationChain;
}
```

### InterchainTokenFactoryStorage

_Storage for this contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

```solidity
struct InterchainTokenFactoryStorage {
  mapping(bytes32 => bytes32) approvedDestinationMinters;
}
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

Constructs the InterchainTokenFactory contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service. |

### _setup

```solidity
function _setup(bytes data) internal
```

Internal function to set up the contract with initial data

_This function should be implemented in derived contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes | Initialization data for the contract |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id of this contract. |

### interchainTokenDeploySalt

```solidity
function interchainTokenDeploySalt(address deployer, bytes32 salt) public view returns (bytes32 deploySalt)
```

Computes the deploy salt for an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address of the deployer. |
| salt | bytes32 | A unique identifier to generate the salt. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The deploy salt for the interchain token. |

### canonicalInterchainTokenDeploySalt

```solidity
function canonicalInterchainTokenDeploySalt(address tokenAddress) public view returns (bytes32 deploySalt)
```

Computes the deploy salt for a canonical interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The deploy salt for the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId)
```

Computes the ID for an interchain token based on the deployer and a salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address that deployed the interchain token. |
| salt | bytes32 | A unique identifier used in the deployment process. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the interchain token. |

### canonicalInterchainTokenId

```solidity
function canonicalInterchainTokenId(address tokenAddress) public view returns (bytes32 tokenId)
```

Computes the ID for a canonical interchain token based on its address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the canonical interchain token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the canonical interchain token. |

### _interchainTokenId

```solidity
function _interchainTokenId(bytes32 deploySalt) internal view returns (bytes32 tokenId)
```

Computes the tokenId for an interchain token based on the deploySalt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The salt used for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the interchain token. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 initialSupply, address minter) external payable returns (bytes32 tokenId)
```

Deploys a new interchain token with specified parameters.

_Creates a new token and optionally mints an initial amount to a specified minter.
This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals for the token. |
| initialSupply | uint256 | The amount of tokens to mint initially (can be zero), allocated to the msg.sender. |
| minter | address | The address to receive the minter and operator role of the token, in addition to ITS. If it is set to `address(0)`, the additional minter isn't set, and can't be added later. This allows creating tokens that are managed only by ITS, reducing trust assumptions. Reverts if the minter is the ITS address since it's already added as a minter. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### approveDeployRemoteInterchainToken

```solidity
function approveDeployRemoteInterchainToken(address deployer, bytes32 salt, string destinationChain, bytes destinationMinter) external
```

Allow the minter to approve the deployer for a remote interchain token deployment that uses a custom destinationMinter address.
This ensures that a token deployer can't choose the destinationMinter itself, and requires the approval of the minter to reduce trust assumptions on the deployer.

### revokeDeployRemoteInterchainToken

```solidity
function revokeDeployRemoteInterchainToken(address deployer, bytes32 salt, string destinationChain) external
```

Allows the minter to revoke a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.

### _deployApprovalKey

```solidity
function _deployApprovalKey(struct InterchainTokenFactory.DeployApproval approval) internal pure returns (bytes32 key)
```

### _useDeployApproval

```solidity
function _useDeployApproval(struct InterchainTokenFactory.DeployApproval approval, bytes destinationMinter) internal
```

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(bytes32 salt, address minter, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to use as the minter of the deployed token on the destination chain. If the destination chain is not EVM, then use the more generic `deployRemoteInterchainToken` function below that allows setting an arbitrary destination minter that was approved by the current minter. |
| destinationChain | string | The name of the destination chain. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainTokenWithMinter

```solidity
function deployRemoteInterchainTokenWithMinter(bytes32 salt, address minter, string destinationChain, bytes destinationMinter, uint256 gasValue) public payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to receive the minter and operator role of the token, in addition to ITS. If the address is `address(0)`, no additional minter is set on the token. Reverts if the minter does not have mint permission for the token. |
| destinationChain | string | The name of the destination chain. |
| destinationMinter | bytes | The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes since the encoding of the account is dependent on the destination chain. If this is empty, then the `minter` of the token on the current chain is used as the destination minter, which makes it convenient when deploying to other EVM chains. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address minter, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.
This method is deprecated and will be removed in the future. Please use the above method instead.

_originalChainName is only allowed to be '', i.e the current chain.
Other source chains are not supported anymore to simplify ITS token deployment behaviour._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChainName | string | The name of the chain where the token originally exists. |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to receive the minter and operator role of the token, in addition to ITS. If the address is `address(0)`, no additional minter is set on the token. Reverts if the minter does not have mint permission for the token. |
| destinationChain | string | The name of the destination chain. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### _deployInterchainToken

```solidity
function _deployInterchainToken(bytes32 salt, string destinationChain, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes minter, uint256 gasValue) internal returns (bytes32 tokenId)
```

Deploys a new interchain token with specified parameters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| destinationChain | string | The name of the destination chain. |
| tokenName | string | The name of the token. |
| tokenSymbol | string | The symbol of the token. |
| tokenDecimals | uint8 | The number of decimals for the token. |
| minter | bytes | The address to receive the initially minted tokens. |
| gasValue | uint256 | The amount of gas to send for the transfer. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### _deployRemoteInterchainToken

```solidity
function _deployRemoteInterchainToken(bytes32 deploySalt, string destinationChain, bytes minter, uint256 gasValue) internal returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deploySalt | bytes32 | The salt used for the deployment. |
| destinationChain | string | The name of the destination chain. |
| minter | bytes | The address to receive the minter and operator role of the token, in addition to ITS. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### registerCanonicalInterchainToken

```solidity
function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Registers a canonical token as an interchain token and deploys its token manager.

_This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the canonical token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the registered canonical token. |

### deployRemoteCanonicalInterchainToken

```solidity
function deployRemoteCanonicalInterchainToken(address originalTokenAddress, string destinationChain, uint256 gasValue) public payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalTokenAddress | address | The address of the original token on the original chain. |
| destinationChain | string | The name of the chain where the token will be deployed. |
| gasValue | uint256 | The gas amount to be sent for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteCanonicalInterchainToken

```solidity
function deployRemoteCanonicalInterchainToken(string originalChain, address originalTokenAddress, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.
This method is deprecated and will be removed in the future. Please use the above method instead.

_originalChain is only allowed to be '', i.e the current chain.
Other source chains are not supported anymore to simplify ITS token deployment behaviour._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChain | string | The name of the chain where the token originally exists. |
| originalTokenAddress | address | The address of the original token on the original chain. |
| destinationChain | string | The name of the chain where the token will be deployed. |
| gasValue | uint256 | The gas amount to be sent for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |
