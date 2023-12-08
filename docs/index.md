# Solidity API

## InterchainTokenFactory

This contract is responsible for deploying new interchain tokens and managing their token managers.

### service

```solidity
contract IInterchainTokenService service
```

### chainNameHash

```solidity
bytes32 chainNameHash
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### gateway

```solidity
contract IAxelarGateway gateway
```

### PREFIX_CANONICAL_TOKEN_SALT

```solidity
bytes32 PREFIX_CANONICAL_TOKEN_SALT
```

### PREFIX_INTERCHAIN_TOKEN_SALT

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_SALT
```

### constructor

```solidity
constructor(address interchainTokenServiceAddress) public
```

Constructs the InterchainTokenFactory contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenServiceAddress | address | The address of the interchain token service. |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id of this contract. |

### interchainTokenSalt

```solidity
function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) public pure returns (bytes32)
```

Calculates the salt for an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainNameHash_ | bytes32 | The hash of the chain name. |
| deployer | address | The address of the deployer. |
| salt | bytes32 | A unique identifier to generate the salt. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The calculated salt for the interchain token. |

### canonicalInterchainTokenSalt

```solidity
function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) public pure returns (bytes32 salt)
```

Calculates the salt for a canonical interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainNameHash_ | bytes32 | The hash of the chain name. |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The calculated salt for the interchain token. |

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

### interchainTokenAddress

```solidity
function interchainTokenAddress(address deployer, bytes32 salt) public view returns (address tokenAddress)
```

Retrieves the address of an interchain token based on the deployer and a salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address that deployed the interchain token. |
| salt | bytes32 | A unique identifier used in the deployment process. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the interchain token. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 initialSupply, address minter) external payable returns (bytes32 tokenId)
```

Deploys a new interchain token with specified parameters.

_Creates a new token and optionally mints an initial amount to a specified minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals for the token. |
| initialSupply | uint256 | The amount of tokens to mint initially (can be zero). |
| minter | address | The address to receive the initially minted tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address minter, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChainName | string | The name of the chain where the token originally exists. |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to distribute the token on the destination chain. |
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

### registerCanonicalInterchainToken

```solidity
function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Registers a canonical token as an interchain token and deploys its token manager.

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
function deployRemoteCanonicalInterchainToken(string originalChain, address originalTokenAddress, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.

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

### _isGatewayToken

```solidity
function _isGatewayToken(address token) internal view returns (bool)
```

Checks if a given token is a gateway token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The address of the token to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool True if the token is a gateway token, false otherwise. |

## InterchainTokenService

This contract is responsible for facilitating interchain token transfers.
It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for interchain transfers to happen.

_The only storage used in this contract is for Express calls.
Furthermore, no ether is intended to or should be sent to this contract except as part of deploy/interchainTransfer payable methods for gas payment._

### gateway

```solidity
contract IAxelarGateway gateway
```

### gasService

```solidity
contract IAxelarGasService gasService
```

### interchainTokenFactory

```solidity
address interchainTokenFactory
```

### chainNameHash

```solidity
bytes32 chainNameHash
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### interchainTokenDeployer

```solidity
address interchainTokenDeployer
```

Returns the address of the interchain token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenManagerDeployer

```solidity
address tokenManagerDeployer
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenManager

```solidity
address tokenManager
```

_Token manager implementation addresses_

### tokenHandler

```solidity
address tokenHandler
```

Returns the address of TokenHandler implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### PREFIX_INTERCHAIN_TOKEN_ID

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_ID
```

### PREFIX_INTERCHAIN_TOKEN_SALT

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_SALT
```

### TOKEN_FACTORY_DEPLOYER

```solidity
address TOKEN_FACTORY_DEPLOYER
```

_Tokens and token managers deployed via the Token Factory contract use a special deployer address.
This removes the dependency on the address the token factory was deployed too to be able to derive the same tokenId._

### MetadataVersion

_Latest version of metadata that's supported._

```solidity
enum MetadataVersion {
  CONTRACT_CALL,
  EXPRESS_CALL
}
```

### LATEST_METADATA_VERSION

```solidity
uint32 LATEST_METADATA_VERSION
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address interchainTokenDeployer_, address gateway_, address gasService_, address interchainTokenFactory_, string chainName_, address tokenManagerImplementation_, address tokenHandler_) public
```

Constructor for the Interchain Token Service.

_All of the variables passed here are stored as immutable variables._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployer_ | address | The address of the TokenManagerDeployer. |
| interchainTokenDeployer_ | address | The address of the InterchainTokenDeployer. |
| gateway_ | address | The address of the AxelarGateway. |
| gasService_ | address | The address of the AxelarGasService. |
| interchainTokenFactory_ | address | The address of the InterchainTokenFactory. |
| chainName_ | string | The name of the chain that this contract is deployed on. |
| tokenManagerImplementation_ | address | The tokenManager implementation. |
| tokenHandler_ | address | The tokenHandler implementation. |

### onlyRemoteService

```solidity
modifier onlyRemoteService(string sourceChain, string sourceAddress)
```

This modifier is used to ensure that only a remote InterchainTokenService can invoke the execute function.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | The source chain of the contract call. |
| sourceAddress | string | The source address that the call came from. |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The contract id of this contract. |

### tokenManagerAddress

```solidity
function tokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_)
```

Calculates the address of a TokenManager from a specific tokenId.

_The TokenManager does not need to exist already._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The deployment address of the TokenManager. |

### validTokenManagerAddress

```solidity
function validTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_)
```

Returns the address of a TokenManager from a specific tokenId.

_The TokenManager needs to exist already._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The deployment address of the TokenManager. |

### validTokenAddress

```solidity
function validTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |

### interchainTokenAddress

```solidity
function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the interchain token associated with the given tokenId.

_The token does not need to exist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the interchain token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a link for a given deployer with a specified salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address of the TokenManager deployer. |
| salt | bytes32 | The salt that the deployer uses for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId that the custom TokenManager would get (or has gotten). |

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256) external view returns (address)
```

Getter function for TokenManager implementation. This will mainly be called by TokenManager proxies
to figure out their implementations.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | tokenManagerAddress The address of the TokenManager implementation. |

### flowLimit

```solidity
function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_)
```

Getter function for the flow limit of an existing TokenManager with a given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The flow limit. |

### flowOutAmount

```solidity
function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_)
```

Getter function for the flow out amount of an existing TokenManager with a given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The flow out amount. |

### flowInAmount

```solidity
function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_)
```

Getter function for the flow in amount of an existing TokenManager with a given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The flow in amount. |

### deployTokenManager

```solidity
function deployTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Used to deploy remote custom TokenManagers.

_At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt to be used during deployment. |
| destinationChain | string | The name of the chain to deploy the TokenManager and standardized token to. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of TokenManager to be deployed. |
| params | bytes | The params that will be used to initialize the TokenManager. |
| gasValue | uint256 | The amount of native tokens to be used to pay for gas for the remote deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed TokenManager. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string destinationChain, string name, string symbol, uint8 decimals, bytes minter, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Used to deploy an interchain token alongside a TokenManager in another chain.

_At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
part of a multicall involving multiple functions that could make remote contract calls. If the `minter` parameter is empty bytes then
a mint/burn TokenManager is used, otherwise a lock/unlock TokenManager is used._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt to be used during deployment. |
| destinationChain | string | The name of the destination chain to deploy to. |
| name | string | The name of the token to be deployed. |
| symbol | string | The symbol of the token to be deployed. |
| decimals | uint8 | The decimals of the token to be deployed. |
| minter | bytes | The address that will be able to mint and burn the deployed token. |
| gasValue | uint256 | The amount of native tokens to be used to pay for gas for the remote deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### contractCallValue

```solidity
function contractCallValue(string sourceChain, string sourceAddress, bytes payload) public view virtual returns (address, uint256)
```

Returns the amount of token that this call is worth.

_If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | The source chain. |
| sourceAddress | string | The source address on the source chain. |
| payload | bytes | The payload sent with the call. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The token address. |
| [1] | uint256 | uint256 The value the call is worth. |

### expressExecute

```solidity
function expressExecute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) external payable
```

Express executes operations based on the payload and selector.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The chain where the transaction originates from. |
| sourceAddress | string | The address of the remote ITS where the transaction originates from. |
| payload | bytes | The encoded data payload for the transaction. |

### _expressExecute

```solidity
function _expressExecute(bytes32 commandId, string sourceChain, bytes payload) internal
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
interchainTransfer that matches the parameters passed here.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id of the transfer being expressed. |
| sourceChain | string | the name of the chain where the interchainTransfer originated from. |
| payload | bytes | the payload of the receive token |

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata, uint256 gasValue) external payable
```

Initiates an interchain transfer of a specified token to a destination chain.

_The function retrieves the TokenManager associated with the tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |
| gasValue | uint256 |  |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes data, uint256 gasValue) external payable
```

Initiates an interchain call contract with interchain token to a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| data | bytes | Additional data to be passed along with the transfer. |
| gasValue | uint256 |  |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit an interchain transfer for the given tokenId.

_Only callable by a token registered under a tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of token to give. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

### setFlowLimits

```solidity
function setFlowLimits(bytes32[] tokenIds, uint256[] flowLimits) external
```

Used to set a flow limit for a token manager that has the service as its operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIds | bytes32[] | An array of the tokenIds of the tokenManagers to set the flow limits of. |
| flowLimits | uint256[] | The flowLimits to set. |

### setTrustedAddress

```solidity
function setTrustedAddress(string chain, string address_) external
```

Used to set a trusted address for a chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | The chain to set the trusted address of. |
| address_ | string | The address to set as trusted. |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

Used to remove a trusted address for a chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | The chain to set the trusted address of. |

### setPauseStatus

```solidity
function setPauseStatus(bool paused) external
```

Allows the owner to pause/unpause the token service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | Boolean value representing whether to pause or unpause. |

### _setup

```solidity
function _setup(bytes params) internal
```

### execute

```solidity
function execute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) external
```

Executes operations based on the payload and selector.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The chain where the transaction originates from. |
| sourceAddress | string | The address of the remote ITS where the transaction originates from. |
| payload | bytes | The encoded data payload for the transaction. |

### contractCallWithTokenValue

```solidity
function contractCallWithTokenValue(string, string, bytes, string, uint256) public view virtual returns (address, uint256)
```

### expressExecuteWithToken

```solidity
function expressExecuteWithToken(bytes32, string, string, bytes, string, uint256) external payable
```

### executeWithToken

```solidity
function executeWithToken(bytes32, string, string, bytes, string, uint256) external pure
```

### _processInterchainTransferPayload

```solidity
function _processInterchainTransferPayload(bytes32 commandId, address expressExecutor, string sourceChain, bytes payload) internal
```

Processes the payload data for a send token call.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| expressExecutor | address | The address of the express executor. Equals `address(0)` if it wasn't expressed. |
| sourceChain | string | The chain where the transaction originates from. |
| payload | bytes | The encoded data payload to be processed. |

### _processDeployTokenManagerPayload

```solidity
function _processDeployTokenManagerPayload(bytes payload) internal
```

Processes a deploy token manager payload.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payload | bytes | The encoded data payload to be processed |

### _processDeployInterchainTokenPayload

```solidity
function _processDeployInterchainTokenPayload(bytes payload) internal
```

Processes a deploy interchain token manager payload.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payload | bytes | The encoded data payload to be processed. |

### _callContract

```solidity
function _callContract(string destinationChain, bytes payload, enum InterchainTokenService.MetadataVersion metadataVersion, uint256 gasValue) internal
```

Calls a contract on a specific destination chain with the given payload

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The target chain where the contract will be called. |
| payload | bytes | The data payload for the transaction. |
| metadataVersion | enum InterchainTokenService.MetadataVersion |  |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _deployRemoteTokenManager

```solidity
function _deployRemoteTokenManager(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager on a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| destinationChain | string | The chain where the token manager will be deployed. |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager to be deployed. |
| params | bytes | Additional parameters for the token manager deployment. |

### _deployRemoteInterchainToken

```solidity
function _deployRemoteInterchainToken(bytes32 tokenId, string name, string symbol, uint8 decimals, bytes minter, string destinationChain, uint256 gasValue) internal
```

Deploys an interchain token on a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals of the token. |
| minter | bytes | The minter address for the token. |
| destinationChain | string | The destination chain where the token will be deployed. |
| gasValue | uint256 | The amount of gas to be paid for the transaction. |

### _deployTokenManager

```solidity
function _deployTokenManager(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to be deployed. |
| params | bytes | Additional parameters for the token manager deployment. |

### _getInterchainTokenSalt

```solidity
function _getInterchainTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt)
```

Computes the salt for an interchain token deployment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The computed salt for the token deployment. |

### _deployInterchainToken

```solidity
function _deployInterchainToken(bytes32 tokenId, bytes minterBytes, string name, string symbol, uint8 decimals) internal returns (address tokenAddress)
```

Deploys an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token. |
| minterBytes | bytes | The minter address for the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals of the token. |

### _decodeMetadata

```solidity
function _decodeMetadata(bytes metadata) internal pure returns (enum InterchainTokenService.MetadataVersion version, bytes data)
```

Decodes the metadata into a version number and data bytes.

_The function expects the metadata to have the version in the first 4 bytes, followed by the actual data._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadata | bytes | The bytes containing the metadata to decode. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| version | enum InterchainTokenService.MetadataVersion | The version number extracted from the metadata. |
| data | bytes | The data bytes extracted from the metadata. |

### _transmitInterchainTransfer

```solidity
function _transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, enum InterchainTokenService.MetadataVersion metadataVersion, bytes data, uint256 gasValue) internal
```

Transmit a callContractWithInterchainToken for the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from, which will also be used for gas reimbursement. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of tokens to send. |
| metadataVersion | enum InterchainTokenService.MetadataVersion | The version of the metadata. |
| data | bytes | The data to be passed with the token transfer. |
| gasValue | uint256 |  |

### _takeToken

```solidity
function _takeToken(bytes32 tokenId, address from, uint256 amount, bool tokenOnly) internal returns (uint256)
```

_Takes token from a sender via the token service. `tokenOnly` indicates if the caller should be restricted to the token only._

### _giveToken

```solidity
function _giveToken(bytes32 tokenId, address to, uint256 amount) internal returns (uint256, address)
```

_Gives token to recipient via the token service._

## TokenHandler

This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.

### giveToken

```solidity
function giveToken(uint256 tokenManagerType, address tokenAddress, address tokenManager, address to, uint256 amount) external payable returns (uint256)
```

This function gives token to a specified address from the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | The address of the token to give. |
| tokenManager | address | The address of the token manager. |
| to | address | The address to give tokens to. |
| amount | uint256 | The amount of tokens to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually given, which could be different for certain token type. |

### takeToken

```solidity
function takeToken(uint256 tokenManagerType, address tokenAddress, address tokenManager, address from, uint256 amount) external payable returns (uint256)
```

This function takes token from a specified address to the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | The address of the token to give. |
| tokenManager | address | The address of the token manager. |
| from | address | The address to take tokens from. |
| amount | uint256 | The amount of token to take. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually taken, which could be different for certain token type. |

### transferTokenFrom

```solidity
function transferTokenFrom(uint256 tokenManagerType, address tokenAddress, address from, address to, uint256 amount) external payable returns (uint256)
```

This function transfers token from and to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | the address of the token to give. |
| from | address | The address to transfer tokens from. |
| to | address | The address to transfer tokens to. |
| amount | uint256 | The amount of token to transfer. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually transferred, which could be different for certain token type. |

### _transferTokenFrom

```solidity
function _transferTokenFrom(address tokenAddress, address from, address to, uint256 amount) internal
```

### _transferTokenFromWithFee

```solidity
function _transferTokenFromWithFee(address tokenAddress, address from, address to, uint256 amount) internal returns (uint256)
```

### _giveTokenMintBurn

```solidity
function _giveTokenMintBurn(address tokenAddress, address to, uint256 amount) internal
```

### _takeTokenMintBurn

```solidity
function _takeTokenMintBurn(address tokenAddress, address from, uint256 amount) internal
```

### _takeTokenMintBurnFrom

```solidity
function _takeTokenMintBurnFrom(address tokenAddress, address from, uint256 amount) internal
```

## InterchainTokenExecutable

Abstract contract that defines an interface for executing arbitrary logic
in the context of interchain token operations.

_This contract should be inherited by contracts that intend to execute custom
logic in response to interchain token actions such as transfers. This contract
will only be called by the interchain token service._

### NotService

```solidity
error NotService(address caller)
```

### interchainTokenService

```solidity
address interchainTokenService
```

### EXECUTE_SUCCESS

```solidity
bytes32 EXECUTE_SUCCESS
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

Creates a new InterchainTokenExecutable contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service that will call this contract. |

### onlyService

```solidity
modifier onlyService()
```

Modifier to restrict function execution to the interchain token service.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

Executes logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens being transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the execution. |

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal virtual
```

Internal function containing the logic to be executed with interchain token transfer.

_Logic must be implemented by derived contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens being transferred. |

## InterchainTokenExpressExecutable

Abstract contract that defines an interface for executing express logic in the context of interchain token operations.

_This contract extends `InterchainTokenExecutable` to provide express execution capabilities. It is intended to be inherited by contracts
that implement express logic for interchain token actions. This contract will only be called by the interchain token service._

### EXPRESS_EXECUTE_SUCCESS

```solidity
bytes32 EXPRESS_EXECUTE_SUCCESS
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

Creates a new InterchainTokenExpressExecutable contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service that will call this contract. |

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

Executes express logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens to be transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the express execution. |

## ERC20

_Implementation of the {IERC20} interface.

This implementation is agnostic to the way tokens are created. This means
that a supply mechanism has to be added in a derived contract using {_mint}.
For a generic mechanism see {ERC20PresetMinterPauser}.

TIP: For a detailed writeup see our guide
https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
to implement supply mechanisms].

We have followed general OpenZeppelin guidelines: functions revert instead
of returning `false` on failure. This behavior is nonetheless conventional
and does not conflict with the expectations of ERC20 applications.

Additionally, an {Approval} event is emitted on calls to {transferFrom}.
This allows applications to reconstruct the allowance for all accounts just
by listening to said events. Other implementations of the EIP may not emit
these events, as it isn't required by the specification.

Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
functions have been added to mitigate the well-known issues around setting
allowances. See {IERC20-approve}._

### balanceOf

```solidity
mapping(address => uint256) balanceOf
```

_Returns the amount of tokens owned by `account`._

### allowance

```solidity
mapping(address => mapping(address => uint256)) allowance
```

_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called._

### totalSupply

```solidity
uint256 totalSupply
```

_Returns the amount of tokens in existence._

### UINT256_MAX

```solidity
uint256 UINT256_MAX
```

### transfer

```solidity
function transfer(address recipient, uint256 amount) external virtual returns (bool)
```

_See {IERC20-transfer}.

Requirements:

- `recipient` cannot be the zero address.
- the caller must have a balance of at least `amount`._

### approve

```solidity
function approve(address spender, uint256 amount) external virtual returns (bool)
```

_See {IERC20-approve}.

NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
`transferFrom`. This is semantically equivalent to an infinite approval.

Requirements:

- `spender` cannot be the zero address._

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool)
```

_See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

Requirements:

- `sender` and `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.
- the caller must have allowance for ``sender``'s tokens of at least
`amount`._

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool)
```

_Atomically increases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address._

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool)
```

_Atomically decreases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.
- `spender` must have allowance for the caller of at least
`subtractedValue`._

### _transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount) internal virtual
```

_Moves tokens `amount` from `sender` to `recipient`.

This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `sender` cannot be the zero address.
- `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`._

### _mint

```solidity
function _mint(address account, uint256 amount) internal virtual
```

_Creates `amount` tokens and assigns them to `account`, increasing
the total supply.

Emits a {Transfer} event with `from` set to the zero address.

Requirements:

- `to` cannot be the zero address._

### _burn

```solidity
function _burn(address account, uint256 amount) internal virtual
```

_Destroys `amount` tokens from `account`, reducing the
total supply.

Emits a {Transfer} event with `to` set to the zero address.

Requirements:

- `account` cannot be the zero address.
- `account` must have at least `amount` tokens._

### _approve

```solidity
function _approve(address owner, address spender, uint256 amount) internal virtual
```

_Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

- `owner` cannot be the zero address.
- `spender` cannot be the zero address._

## ERC20Permit

_Extension of ERC20 to include permit functionality (EIP-2612).
Allows for approval of ERC20 tokens by signature rather than transaction._

### PermitExpired

```solidity
error PermitExpired()
```

### InvalidS

```solidity
error InvalidS()
```

### InvalidV

```solidity
error InvalidV()
```

### InvalidSignature

```solidity
error InvalidSignature()
```

### nameHash

```solidity
bytes32 nameHash
```

_Represents hash of the EIP-712 Domain Separator._

### nonces

```solidity
mapping(address => uint256) nonces
```

_Mapping of nonces for each address._

### _setNameHash

```solidity
function _setNameHash(string name) internal
```

Internal function to set the token name hash

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The token name |

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() public view returns (bytes32)
```

Calculates the domain separator.

_This is not cached because chainid can change on chain forks._

### permit

```solidity
function permit(address issuer, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

Permit the designated spender to spend the holder's tokens

_The permit function is used to allow a holder to designate a spender
to spend tokens on their behalf via a signed message._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| issuer | address | The address of the token holder |
| spender | address | The address of the designated spender |
| value | uint256 | The number of tokens to be spent |
| deadline | uint256 | The time at which the permission to spend expires |
| v | uint8 | The recovery id of the signature |
| r | bytes32 | Half of the ECDSA signature pair |
| s | bytes32 | Half of the ECDSA signature pair |

## InterchainToken

This contract implements an interchain token which extends InterchainToken functionality.

_This contract also inherits Minter and Implementation logic._

### name

```solidity
string name
```

Getter for the name of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### symbol

```solidity
string symbol
```

Getter for the symbol of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### decimals

```solidity
uint8 decimals
```

Getter for the decimals of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### tokenId

```solidity
bytes32 tokenId
```

### interchainTokenService_

```solidity
address interchainTokenService_
```

### INITIALIZED_SLOT

```solidity
bytes32 INITIALIZED_SLOT
```

### constructor

```solidity
constructor(address interchainTokenServiceAddress) public
```

Constructs the InterchainToken contract.

_Makes the implementation act as if it has been setup already to disallow calls to init() (even though that would not achieve anything really)._

### _isInitialized

```solidity
function _isInitialized() internal view returns (bool initialized)
```

Returns true if the contract has been setup.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialized | bool | True if the contract has been setup, false otherwise. |

### _initialize

```solidity
function _initialize() internal
```

Sets initialized to true, to allow only a single init.

### interchainTokenService

```solidity
function interchainTokenService() public view returns (address)
```

Returns the interchain token service

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The interchain token service contract |

### interchainTokenId

```solidity
function interchainTokenId() public view returns (bytes32)
```

Returns the tokenId for this token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The token manager contract. |

### init

```solidity
function init(bytes32 tokenId_, address minter, string tokenName, string tokenSymbol, uint8 tokenDecimals) external
```

Setup function to initialize contract parameters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId_ | bytes32 | The tokenId of the token. |
| minter | address | The address of the token minter. |
| tokenName | string | The name of the token. |
| tokenSymbol | string | The symbopl of the token. |
| tokenDecimals | uint8 | The decimals of the token. |

### mint

```solidity
function mint(address account, uint256 amount) external
```

Function to mint new tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will receive the minted tokens. |
| amount | uint256 | The amount of tokens to mint. |

### burn

```solidity
function burn(address account, uint256 amount) external
```

Function to burn tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will have its tokens burnt. |
| amount | uint256 | The amount of tokens to burn. |

### _spendAllowance

```solidity
function _spendAllowance(address sender, address spender, uint256 amount) internal
```

A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.

_Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient._

## InterchainTokenStandard

The is an abstract contract that needs to be extended with an ERC20 implementation. See `InterchainToken` for an example implementation.

### interchainTokenId

```solidity
function interchainTokenId() public view virtual returns (bytes32 tokenId_)
```

Getter for the tokenId used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId_ | bytes32 | The tokenId that this token is registerred under. |

### interchainTokenService

```solidity
function interchainTokenService() public view virtual returns (address service)
```

Getter for the interchain token service.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| service | address | The address of the interchain token service. |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | The string representation of the destination chain. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer. |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address from, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) internal virtual
```

A method to be overwritten that will be called before an interchain transfer. One can approve the tokenManager here if needed,
to allow users for a 1-call transfer in case of a lock-unlock token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | The string representation of the destination chain. |
| destinationAddress | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer. |

### _spendAllowance

```solidity
function _spendAllowance(address sender, address spender, uint256 amount) internal virtual
```

A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.

_Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient._

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

## IBaseTokenManager

This contract is defines the base token manager interface implemented by all token managers.

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32)
```

A function that returns the token id.

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

A function that should return the address of the token.
Must be overridden in the inheriting contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address address of the token. |

### getTokenAddressFromParams

```solidity
function getTokenAddressFromParams(bytes params) external pure returns (address)
```

A function that should return the token address from the init params.

## IERC20BurnableFrom

Interface of the ERC20 standard as defined in the EIP.

### burnFrom

```solidity
function burnFrom(address from, uint256 amount) external
```

Function to burn tokens.

_Requires the caller to have allowance for `amount` on `from`.
Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt. |
| amount | uint256 | The amount of tokens to burn. |

## IERC20MintableBurnable

_Interface of the ERC20 standard as defined in the EIP._

### mint

```solidity
function mint(address to, uint256 amount) external
```

Function to mint new tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address that will receive the minted tokens. |
| amount | uint256 | The amount of tokens to mint. |

### burn

```solidity
function burn(address from, uint256 amount) external
```

Function to burn tokens.

_Can only be called by the minter address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt. |
| amount | uint256 | The amount of tokens to burn. |

## IERC20Named

_Interface of the ERC20 standard as defined in the EIP._

### name

```solidity
function name() external view returns (string)
```

Getter for the name of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | string Name of the token. |

### symbol

```solidity
function symbol() external view returns (string)
```

Getter for the symbol of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | string The symbol of the token. |

### decimals

```solidity
function decimals() external view returns (uint8)
```

Getter for the decimals of the token.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | uint8 The decimals of the token. |

## IFlowLimit

Interface for flow limit logic for interchain token transfers.

### FlowLimitExceeded

```solidity
error FlowLimitExceeded(uint256 limit, uint256 flowAmount, address tokenManager)
```

### FlowLimitSet

```solidity
event FlowLimitSet(bytes32 tokenId, address operator, uint256 flowLimit_)
```

### flowLimit

```solidity
function flowLimit() external view returns (uint256 flowLimit_)
```

Returns the current flow limit.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount. |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount. |

## IInterchainToken

_Extends IInterchainTokenStandard and IMinter._

### InterchainTokenServiceAddressZero

```solidity
error InterchainTokenServiceAddressZero()
```

### TokenIdZero

```solidity
error TokenIdZero()
```

### TokenNameEmpty

```solidity
error TokenNameEmpty()
```

### AlreadyInitialized

```solidity
error AlreadyInitialized()
```

### interchainTokenService

```solidity
function interchainTokenService() external view returns (address interchainTokenServiceAddress)
```

Getter for the interchain token service contract.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenServiceAddress | address | The interchain token service address. |

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32 tokenId_)
```

Getter for the tokenId used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId_ | bytes32 | The tokenId for this token. |

### init

```solidity
function init(bytes32 tokenId_, address minter, string tokenName, string tokenSymbol, uint8 tokenDecimals) external
```

Setup function to initialize contract parameters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId_ | bytes32 | The tokenId of the token. |
| minter | address | The address of the token minter. |
| tokenName | string | The name of the token. |
| tokenSymbol | string | The symbopl of the token. |
| tokenDecimals | uint8 | The decimals of the token. |

## IInterchainTokenDeployer

This interface is used to deploy new instances of the InterchainTokenProxy contract.

### AddressZero

```solidity
error AddressZero()
```

### TokenDeploymentFailed

```solidity
error TokenDeploymentFailed()
```

### implementationAddress

```solidity
function implementationAddress() external view returns (address)
```

Returns the interchain token implementation address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The interchain token implementation address. |

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

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, bytes32 tokenId, address minter, string name, string symbol, uint8 decimals) external returns (address tokenAddress)
```

Deploys a new instance of the InterchainTokenProxy contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used by Create3Deployer. |
| tokenId | bytes32 | tokenId of the token. |
| minter | address | Address of the minter. |
| name | string | Name of the token. |
| symbol | string | Symbol of the token. |
| decimals | uint8 | Decimals of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of the deployed token. |

## IInterchainTokenExecutable

Contracts should implement this interface to accept calls from the InterchainTokenService.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

This will be called after the tokens are sent to this contract.

_Execution should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id for the call. |
| sourceChain | string | The name of the source chain. |
| sourceAddress | bytes | The address that sent the contract call. |
| data | bytes | The data to be processed. |
| tokenId | bytes32 | The tokenId of the token manager managing the token. |
| token | address | The address of the token. |
| amount | uint256 | The amount of tokens that were sent. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the execution. |

## IInterchainTokenExpressExecutable

Contracts should implement this interface to accept express calls from the InterchainTokenService.

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

Executes express logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id for the call. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens to be transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the express execution. |

## IInterchainTokenFactory

This interface defines functions for deploying new interchain tokens and managing their token managers.

### ZeroAddress

```solidity
error ZeroAddress()
```

### InvalidChainName

```solidity
error InvalidChainName()
```

### NotMinter

```solidity
error NotMinter(address minter)
```

### NotOperator

```solidity
error NotOperator(address operator)
```

### GatewayToken

```solidity
error GatewayToken(address tokenAddress)
```

### chainNameHash

```solidity
function chainNameHash() external view returns (bytes32)
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The hash of the chain name. |

### interchainTokenSalt

```solidity
function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) external view returns (bytes32)
```

Calculates the salt for an interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainNameHash_ | bytes32 | The hash of the chain name. |
| deployer | address | The address of the deployer. |
| salt | bytes32 | A unique identifier to generate the salt. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The calculated salt for the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId)
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

### interchainTokenAddress

```solidity
function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress)
```

Retrieves the address of an interchain token based on the deployer and a salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployer | address | The address that deployed the interchain token. |
| salt | bytes32 | A unique identifier used in the deployment process. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the interchain token. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 initialSupply, address minter) external payable returns (bytes32 tokenId)
```

Deploys a new interchain token with specified parameters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The unique salt for deploying the token. |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| decimals | uint8 | The number of decimals for the token. |
| initialSupply | uint256 | The amount of tokens to mint initially (can be zero). |
| minter | address | The address to receive the initially minted tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address minter, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a remote interchain token on a specified destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| originalChainName | string | The name of the chain where the token originally exists. |
| salt | bytes32 | The unique salt for deploying the token. |
| minter | address | The address to distribute the token on the destination chain. |
| destinationChain | string | The name of the destination chain. |
| gasValue | uint256 | The amount of gas to send for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### canonicalInterchainTokenSalt

```solidity
function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) external view returns (bytes32 salt)
```

Calculates the salt for a canonical interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainNameHash_ | bytes32 | The hash of the chain name. |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The calculated salt for the interchain token. |

### canonicalInterchainTokenId

```solidity
function canonicalInterchainTokenId(address tokenAddress) external view returns (bytes32 tokenId)
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

### registerCanonicalInterchainToken

```solidity
function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Registers a canonical token as an interchain token and deploys its token manager.

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
function deployRemoteCanonicalInterchainToken(string originalChain, address originalTokenAddress, string destinationChain, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a canonical interchain token on a remote chain.

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
| tokenId | bytes32 | The tokenId corresponding to the deployed canonical InterchainToken. |

## IInterchainTokenService

Interface for the Interchain Token Service

### InvalidTokenManagerImplementationType

```solidity
error InvalidTokenManagerImplementationType(address implementation)
```

### InvalidChainName

```solidity
error InvalidChainName()
```

### NotRemoteService

```solidity
error NotRemoteService()
```

### TokenManagerDoesNotExist

```solidity
error TokenManagerDoesNotExist(bytes32 tokenId)
```

### NotToken

```solidity
error NotToken(address caller, address token)
```

### ExecuteWithInterchainTokenFailed

```solidity
error ExecuteWithInterchainTokenFailed(address contractAddress)
```

### ExpressExecuteWithInterchainTokenFailed

```solidity
error ExpressExecuteWithInterchainTokenFailed(address contractAddress)
```

### GatewayToken

```solidity
error GatewayToken()
```

### TokenManagerDeploymentFailed

```solidity
error TokenManagerDeploymentFailed(bytes error)
```

### InterchainTokenDeploymentFailed

```solidity
error InterchainTokenDeploymentFailed(bytes error)
```

### InvalidMessageType

```solidity
error InvalidMessageType(uint256 messageType)
```

### InvalidMetadataVersion

```solidity
error InvalidMetadataVersion(uint32 version)
```

### ExecuteWithTokenNotSupported

```solidity
error ExecuteWithTokenNotSupported()
```

### InvalidExpressMessageType

```solidity
error InvalidExpressMessageType(uint256 messageType)
```

### TakeTokenFailed

```solidity
error TakeTokenFailed(bytes data)
```

### GiveTokenFailed

```solidity
error GiveTokenFailed(bytes data)
```

### TokenHandlerFailed

```solidity
error TokenHandlerFailed(bytes data)
```

### EmptyData

```solidity
error EmptyData()
```

### InterchainTransfer

```solidity
event InterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes32 dataHash)
```

### InterchainTransferReceived

```solidity
event InterchainTransferReceived(bytes32 commandId, bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes32 dataHash)
```

### TokenManagerDeploymentStarted

```solidity
event TokenManagerDeploymentStarted(bytes32 tokenId, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeploymentStarted

```solidity
event InterchainTokenDeploymentStarted(bytes32 tokenId, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes minter, string destinationChain)
```

### TokenManagerDeployed

```solidity
event TokenManagerDeployed(bytes32 tokenId, address tokenManager, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeployed

```solidity
event InterchainTokenDeployed(bytes32 tokenId, address tokenAddress, address minter, string name, string symbol, uint8 decimals)
```

### InterchainTokenIdClaimed

```solidity
event InterchainTokenIdClaimed(bytes32 tokenId, address deployer, bytes32 salt)
```

### tokenManagerDeployer

```solidity
function tokenManagerDeployer() external view returns (address tokenManagerDeployerAddress)
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployerAddress | address | The address of the token manager deployer contract. |

### interchainTokenDeployer

```solidity
function interchainTokenDeployer() external view returns (address interchainTokenDeployerAddress)
```

Returns the address of the interchain token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenDeployerAddress | address | The address of the interchain token deployer contract. |

### tokenManager

```solidity
function tokenManager() external view returns (address tokenManagerAddress_)
```

Returns the address of TokenManager implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager contract. |

### tokenHandler

```solidity
function tokenHandler() external view returns (address tokenHandlerAddress)
```

Returns the address of TokenHandler implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenHandlerAddress | address | The address of the token handler contract. |

### chainNameHash

```solidity
function chainNameHash() external view returns (bytes32)
```

Returns the hash of the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The hash of the chain name. |

### tokenManagerAddress

```solidity
function tokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress_)
```

Returns the address of the token manager associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager. |

### validTokenManagerAddress

```solidity
function validTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress_)
```

Returns the address of the valid token manager associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the valid token manager. |

### validTokenAddress

```solidity
function validTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the token. |

### interchainTokenAddress

```solidity
function interchainTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the interchain token associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the interchain token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | The address of the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address operator_, bytes32 salt) external view returns (bytes32 tokenId)
```

Returns the custom tokenId associated with the given operator and salt.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The operator address. |
| salt | bytes32 | The salt used for token id calculation. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The custom tokenId associated with the operator and salt. |

### deployTokenManager

```solidity
function deployTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a custom token manager contract on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used for token manager deployment. |
| destinationChain | string | The name of the destination chain. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager. |
| params | bytes | The deployment parameters. |
| gasValue | uint256 | The gas value for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId associated with the token manager. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string destinationChain, string name, string symbol, uint8 decimals, bytes minter, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys and registers an interchain token on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used for token deployment. |
| destinationChain | string | The name of the destination chain. Use '' for this chain. |
| name | string | The name of the interchain tokens. |
| symbol | string | The symbol of the interchain tokens. |
| decimals | uint8 | The number of decimals for the interchain tokens. |
| minter | bytes | The minter data for mint/burn operations. |
| gasValue | uint256 | The gas value for deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId corresponding to the deployed InterchainToken. |

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata, uint256 gasValue) external payable
```

Initiates an interchain transfer of a specified token to a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |
| gasValue | uint256 |  |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes data, uint256 gasValue) external payable
```

Initiates an interchain call contract with interchain token to a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier of the token to be transferred. |
| destinationChain | string | The destination chain to send the tokens to. |
| destinationAddress | bytes | The address on the destination chain to send the tokens to. |
| amount | uint256 | The amount of tokens to be transferred. |
| data | bytes | Additional data to be passed along with the transfer. |
| gasValue | uint256 |  |

### setFlowLimits

```solidity
function setFlowLimits(bytes32[] tokenIds, uint256[] flowLimits) external
```

Sets the flow limits for multiple tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIds | bytes32[] | An array of tokenIds. |
| flowLimits | uint256[] | An array of flow limits corresponding to the tokenIds. |

### flowLimit

```solidity
function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_)
```

Returns the flow limit for a specific token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The flow limit for the token. |

### flowOutAmount

```solidity
function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_)
```

Returns the total amount of outgoing flow for a specific token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The total amount of outgoing flow for the token. |

### flowInAmount

```solidity
function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_)
```

Returns the total amount of incoming flow for a specific token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The total amount of incoming flow for the token. |

### setPauseStatus

```solidity
function setPauseStatus(bool paused) external
```

Allows the owner to pause/unpause the token service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | whether to pause or unpause. |

## IInterchainTokenStandard

_Interface of the ERC20 standard as defined in the EIP._

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method.

_We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could use metadata to specify a function to invoke, or for other purposes as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | The string representation of the destination chain. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract.) |

## IMinter

An interface for a contract module which provides a basic access control mechanism, where
there is an account (a minter) that can be granted exclusive access to specific functions.

### transferMintership

```solidity
function transferMintership(address minter_) external
```

Change the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### proposeMintership

```solidity
function proposeMintership(address minter_) external
```

Proposed a change of the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### acceptMintership

```solidity
function acceptMintership(address fromMinter) external
```

Accept a change of the minter of the contract.

_Can only be called by the proposed minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromMinter | address | The previous minter. |

### isMinter

```solidity
function isMinter(address addr) external view returns (bool)
```

Query if an address is a minter

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is a minter. |

## IOperator

An interface for a contract module which provides a basic access control mechanism, where
there is an account (a operator) that can be granted exclusive access to specific functions.

### transferOperatorship

```solidity
function transferOperatorship(address operator_) external
```

Change the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator. |

### proposeOperatorship

```solidity
function proposeOperatorship(address operator_) external
```

Proposed a change of the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator. |

### acceptOperatorship

```solidity
function acceptOperatorship(address fromOperator) external
```

Accept a proposed change of operatorship.

_Can only be called by the proposed operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromOperator | address | The previous operator of the contract. |

### isOperator

```solidity
function isOperator(address addr) external view returns (bool)
```

Query if an address is a operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is an operator. |

## ITokenHandler

This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.

### UnsupportedTokenManagerType

```solidity
error UnsupportedTokenManagerType(uint256 tokenManagerType)
```

### giveToken

```solidity
function giveToken(uint256 tokenManagerType, address tokenAddress, address tokenManager, address to, uint256 amount) external payable returns (uint256)
```

This function gives token to a specified address from the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | The address of the token to give. |
| tokenManager | address | The address of the token manager. |
| to | address | The address to give tokens to. |
| amount | uint256 | The amount of tokens to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually given, which could be different for certain token type. |

### takeToken

```solidity
function takeToken(uint256 tokenManagerType, address tokenAddress, address tokenManager, address from, uint256 amount) external payable returns (uint256)
```

This function takes token from a specified address to the token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | The address of the token to give. |
| tokenManager | address | The address of the token manager. |
| from | address | The address to take tokens from. |
| amount | uint256 | The amount of token to take. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually taken, which could be different for certain token type. |

### transferTokenFrom

```solidity
function transferTokenFrom(uint256 tokenManagerType, address tokenAddress, address from, address to, uint256 amount) external payable returns (uint256)
```

This function transfers token from and to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The token manager type. |
| tokenAddress | address | the address of the token to give. |
| from | address | The address to transfer tokens from. |
| to | address | The address to transfer tokens to. |
| amount | uint256 | The amount of token to transfer. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The amount of token actually transferred, which could be different for certain token type. |

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

## ITokenManagerDeployer

This interface is used to deploy new instances of the TokenManagerProxy contract.

### AddressZero

```solidity
error AddressZero()
```

### TokenManagerDeploymentFailed

```solidity
error TokenManagerDeploymentFailed()
```

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable returns (address tokenManager)
```

Deploys a new instance of the TokenManagerProxy contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The token ID. |
| implementationType | uint256 | Token manager implementation type. |
| params | bytes | Additional parameters used in the setup of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager | address | Address of the deployed tokenManager. |

## ITokenManagerImplementation

Interface for returning the token manager implementation type.

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress_)
```

Returns the implementation address for a given token manager type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | The type of token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | The address of the token manager implementation. |

## ITokenManagerProxy

This interface is for a proxy for token manager contracts.

### ZeroAddress

```solidity
error ZeroAddress()
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

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32)
```

Returns the interchain token ID of the token manager.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The interchain token ID of the token manager. |

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

Returns token address that this token manager manages.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The token address. |

### getImplementationTypeAndTokenAddress

```solidity
function getImplementationTypeAndTokenAddress() external view returns (uint256, address)
```

Returns implementation type and token address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The implementation type. |
| [1] | address | address The token address. |

## ITokenManagerType

A simple interface that defines all the token manager types.

### TokenManagerType

```solidity
enum TokenManagerType {
  MINT_BURN,
  MINT_BURN_FROM,
  LOCK_UNLOCK,
  LOCK_UNLOCK_FEE
}
```

## ITransmitInterchainToken

Interface for transmiting interchain tokens via the interchain token service

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit an interchain transfer for the given tokenId.

_Only callable by a token registered under a tokenId._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token (which must be the msg.sender). |
| sourceAddress | address | The address where the token is coming from. |
| destinationChain | string | The name of the chain to send tokens to. |
| destinationAddress | bytes | The destinationAddress for the interchainTransfer. |
| amount | uint256 | The amount of token to give. |
| metadata | bytes | Optional metadata for the call for additional effects (such as calling a destination contract). |

## InterchainProxy

This contract is a proxy for interchainTokenService and interchainTokenFactory.

_This contract implements Proxy._

### constructor

```solidity
constructor(address implementationAddress, address owner, bytes setupParams) public
```

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

## InvalidService

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256) external pure returns (address)
```

## TestERC20

### transferFromWithoutApprove

```solidity
function transferFromWithoutApprove(address sender, address recipient, uint256 amount) external virtual returns (bool)
```

## TestFeeOnTransferToken

### service

```solidity
address service
```

### tokenId

```solidity
bytes32 tokenId
```

### tokenManagerRequiresApproval_

```solidity
bool tokenManagerRequiresApproval_
```

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### decimals

```solidity
uint8 decimals
```

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_, address service_, bytes32 tokenId_) public
```

### interchainTokenService

```solidity
function interchainTokenService() public view returns (address)
```

Getter for the interchain token service.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

### interchainTokenId

```solidity
function interchainTokenId() public view returns (bytes32)
```

Getter for the tokenId used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 |  |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address sender, string, bytes, uint256 amount, bytes) internal
```

### _spendAllowance

```solidity
function _spendAllowance(address sender, address spender, uint256 amount) internal
```

A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.

_Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient._

### setTokenManagerRequiresApproval

```solidity
function setTokenManagerRequiresApproval(bool requiresApproval) public
```

### mint

```solidity
function mint(address account, uint256 amount) external
```

### burn

```solidity
function burn(address account, uint256 amount) external
```

### setTokenId

```solidity
function setTokenId(bytes32 tokenId_) external
```

### _transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount) internal virtual
```

_Moves tokens `amount` from `sender` to `recipient`.

This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `sender` cannot be the zero address.
- `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`._

## TestFeeOnTransferTokenInvalid

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_, address service_, bytes32 tokenId_) public
```

### _transfer

```solidity
function _transfer(address, address, uint256 amount) internal
```

## TestFeeOnTransferTokenNoFee

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_, address service_, bytes32 tokenId_) public
```

### _transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount) internal
```

_Moves tokens `amount` from `sender` to `recipient`.

This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `sender` cannot be the zero address.
- `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`._

## TestInterchainExecutable

### MessageReceived

```solidity
event MessageReceived(bytes32 commandId, string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount)
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### lastMessage

```solidity
string lastMessage
```

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal
```

Internal function containing the logic to be executed with interchain token transfer.

_Logic must be implemented by derived contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens being transferred. |

## Invalid

```solidity
error Invalid()
```

## TestInterchainToken

### placeholder

```solidity
string placeholder
```

### constructor

```solidity
constructor() public
```

### spendAllowance

```solidity
function spendAllowance(address sender, address spender, uint256 amount) external
```

## TestInterchainTokenService

### LatestMetadataVersionMismatch

```solidity
error LatestMetadataVersionMismatch(uint32 const, uint32 calculated)
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address interchainTokenDeployer_, address gateway_, address gasService_, address interchainTokenFactory_, string chainName_, address tokenManager_, address tokenHandler_) public
```

### setupTest

```solidity
function setupTest(bytes params) external
```

### callContract

```solidity
function callContract(string destinationChain, bytes payload, enum InterchainTokenService.MetadataVersion metadataVersion, uint256 gasValue) external payable
```

## TestInterchainTokenStandard

### service

```solidity
address service
```

### tokenId

```solidity
bytes32 tokenId
```

### tokenManagerRequiresApproval_

```solidity
bool tokenManagerRequiresApproval_
```

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### decimals

```solidity
uint8 decimals
```

### AllowanceExceeded

```solidity
error AllowanceExceeded()
```

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_, address service_, bytes32 tokenId_) public
```

### interchainTokenService

```solidity
function interchainTokenService() public view returns (address)
```

Getter for the interchain token service.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

### interchainTokenId

```solidity
function interchainTokenId() public view returns (bytes32)
```

Getter for the tokenId used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 |  |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address sender, string, bytes, uint256 amount, bytes) internal
```

### _spendAllowance

```solidity
function _spendAllowance(address sender, address spender, uint256 amount) internal
```

A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.

_Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient._

### setTokenManagerRequiresApproval

```solidity
function setTokenManagerRequiresApproval(bool requiresApproval) public
```

### mint

```solidity
function mint(address account, uint256 amount) external
```

### burn

```solidity
function burn(address account, uint256 amount) external
```

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) external
```

### setTokenId

```solidity
function setTokenId(bytes32 tokenId_) external
```

## TestInvalidInterchainExecutable

### EXECUTE_FAILURE

```solidity
bytes32 EXECUTE_FAILURE
```

### EXPRESS_EXECUTE_FAILURE

```solidity
bytes32 EXPRESS_EXECUTE_FAILURE
```

### MessageReceived

```solidity
event MessageReceived(bytes32 commandId, string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount)
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### lastMessage

```solidity
string lastMessage
```

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

Executes express logic in the context of an interchain token transfer.

_Only callable by the interchain token service._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens to be transferred. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 Hash indicating success of the express execution. |

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(bytes32 commandId, string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal
```

Internal function containing the logic to be executed with interchain token transfer.

_Logic must be implemented by derived contracts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The unique message id. |
| sourceChain | string | The source chain of the token transfer. |
| sourceAddress | bytes | The source address of the token transfer. |
| data | bytes | The data associated with the token transfer. |
| tokenId | bytes32 | The token ID. |
| token | address | The token address. |
| amount | uint256 | The amount of tokens being transferred. |

## TestMintableBurnableERC20

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### decimals

```solidity
uint8 decimals
```

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_) public
```

### mint

```solidity
function mint(address account, uint256 amount) external
```

### burn

```solidity
function burn(address account, uint256 amount) external
```

## TestTokenManager

### constructor

```solidity
constructor(address service) public
```

### addOperator

```solidity
function addOperator(address operator) external
```

## TestTokenManagerProxy

### constructor

```solidity
constructor(address interchainTokenService_, uint256 implementationType_, bytes32 tokenId, bytes params) public
```

### getContractId

```solidity
function getContractId() external pure returns (bytes32)
```

## TestFlowLimit

### Invalid

```solidity
error Invalid()
```

### TOKEN_ID

```solidity
bytes32 TOKEN_ID
```

### placeholder

```solidity
string placeholder
```

### constructor

```solidity
constructor() public
```

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit) external
```

### addFlowIn

```solidity
function addFlowIn(uint256 flowInAmount) external
```

### addFlowOut

```solidity
function addFlowOut(uint256 flowOutAmount) external
```

## TestFlowLimitLiveNetwork

### FLOW_LIMIT_SLOT

```solidity
uint256 FLOW_LIMIT_SLOT
```

### PREFIX_FLOW_OUT_AMOUNT

```solidity
uint256 PREFIX_FLOW_OUT_AMOUNT
```

### PREFIX_FLOW_IN_AMOUNT

```solidity
uint256 PREFIX_FLOW_IN_AMOUNT
```

### TOKEN_ID

```solidity
bytes32 TOKEN_ID
```

### EPOCH_TIME

```solidity
uint256 EPOCH_TIME
```

### flowLimit

```solidity
function flowLimit() public view returns (uint256 flowLimit_)
```

Returns the current flow limit.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |

### _setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit_) internal
```

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount. |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount. |

### _addFlow

```solidity
function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount_) internal
```

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount_) internal
```

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit_) external
```

### addFlowIn

```solidity
function addFlowIn(uint256 flowInAmount_) external
```

### addFlowOut

```solidity
function addFlowOut(uint256 flowOutAmount_) external
```

## TestMinter

### nonce

```solidity
uint256 nonce
```

### constructor

```solidity
constructor(address minter) public
```

### testMinter

```solidity
function testMinter() external
```

### minterRole

```solidity
function minterRole() external pure returns (uint8)
```

## TestOperator

### nonce

```solidity
uint256 nonce
```

### constructor

```solidity
constructor(address operator) public
```

### testOperatorable

```solidity
function testOperatorable() external
```

### operatorRole

```solidity
function operatorRole() external pure returns (uint8)
```

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

## FlowLimit

Implements flow limit logic for interchain token transfers.

_This contract implements low-level assembly for optimization purposes._

### FLOW_LIMIT_SLOT

```solidity
uint256 FLOW_LIMIT_SLOT
```

### PREFIX_FLOW_OUT_AMOUNT

```solidity
uint256 PREFIX_FLOW_OUT_AMOUNT
```

### PREFIX_FLOW_IN_AMOUNT

```solidity
uint256 PREFIX_FLOW_IN_AMOUNT
```

### EPOCH_TIME

```solidity
uint256 EPOCH_TIME
```

### flowLimit

```solidity
function flowLimit() public view returns (uint256 flowLimit_)
```

Returns the current flow limit.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |

### _setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit_, bytes32 tokenId) internal
```

Internal function to set the flow limit.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The value to set the flow limit to. |
| tokenId | bytes32 | The id of the token to set the flow limit for. |

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

Returns the slot which is used to get the flow out amount for a specific epoch.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow out amount for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow out amount from. |

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow in amount for a specific epoch._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow in amount for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow in amount from. |

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount. |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount. |

### _addFlow

```solidity
function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

Adds a flow amount while ensuring it does not exceed the flow limit.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value. |
| slotToAdd | uint256 | The slot to add the flow to. |
| slotToCompare | uint256 | The slot to compare the flow against. |
| flowAmount | uint256 | The flow amount to add. |

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount_) internal
```

Adds a flow out amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The flow out amount to add. |

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount_) internal
```

Adds a flow in amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The flow in amount to add. |

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

## Minter

A contract module which provides a basic access control mechanism, where
there is an account (a minter) that can be granted exclusive access to
specific functions.

_This module is used through inheritance._

### _addMinter

```solidity
function _addMinter(address minter_) internal
```

Internal function that stores the new minter address in the correct storage slot.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### transferMintership

```solidity
function transferMintership(address minter_) external
```

Changes the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### proposeMintership

```solidity
function proposeMintership(address minter_) external
```

Proposes a change of the minter of the contract.

_Can only be called by the current minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter_ | address | The address of the new minter. |

### acceptMintership

```solidity
function acceptMintership(address fromMinter) external
```

Accept a change of the minter of the contract.

_Can only be called by the proposed minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromMinter | address | The previous minter. |

### isMinter

```solidity
function isMinter(address addr) external view returns (bool)
```

Query if an address is a minter

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is a minter. |

## Operator

A contract module which provides a basic access control mechanism, where
there is an account (a operator) that can be granted exclusive access to
specific functions.

_This module is used through inheritance._

### _addOperator

```solidity
function _addOperator(address operator) internal
```

Internal function that stores the new operator address in the correct storage slot

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator |

### transferOperatorship

```solidity
function transferOperatorship(address operator) external
```

Change the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator. |

### proposeOperatorship

```solidity
function proposeOperatorship(address operator) external
```

Propose a change of the operator of the contract.

_Can only be called by the current operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the new operator. |

### acceptOperatorship

```solidity
function acceptOperatorship(address fromOperator) external
```

Accept a proposed change of operatorship.

_Can only be called by the proposed operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fromOperator | address | The previous operator of the contract. |

### isOperator

```solidity
function isOperator(address addr) external view returns (bool)
```

Query if an address is a operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Boolean value representing whether or not the address is an operator. |

## RolesConstants

This contract contains enum values representing different contract roles.

### Roles

```solidity
enum Roles {
  MINTER,
  OPERATOR,
  FLOW_LIMITER
}
```

## TokenManagerDeployer

This contract is used to deploy new instances of the TokenManagerProxy contract.

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable returns (address tokenManager)
```

Deploys a new instance of the TokenManagerProxy contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier for the token |
| implementationType | uint256 | Token manager implementation type |
| params | bytes | Additional parameters used in the setup of the token manager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager | address | The address of the deployed tokenManager |

