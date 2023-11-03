# Solidity API

## InterchainTokenService

This contract is responsible for facilitating cross chain token transfers.
It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.

_The only storage used here is for ExpressCalls_

### implementationLockUnlock

```solidity
address implementationLockUnlock
```

### implementationMintBurn

```solidity
address implementationMintBurn
```

### implementationMintBurnFrom

```solidity
address implementationMintBurnFrom
```

### implementationLockUnlockFee

```solidity
address implementationLockUnlockFee
```

### gateway

```solidity
contract IAxelarGateway gateway
```

### gasService

```solidity
contract IAxelarGasService gasService
```

### interchainAddressTracker

```solidity
contract IInterchainAddressTracker interchainAddressTracker
```

Returns the address of the interchain router contract.

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

### interchainTokenDeployer

```solidity
address interchainTokenDeployer
```

Returns the address of the standardized token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### chainNameHash

```solidity
bytes32 chainNameHash
```

### PREFIX_TOKEN_ID

```solidity
bytes32 PREFIX_TOKEN_ID
```

### PREFIX_INTERCHAIN_TOKEN_SALT

```solidity
bytes32 PREFIX_INTERCHAIN_TOKEN_SALT
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address interchainTokenDeployer_, address gateway_, address gasService_, address interchainRouter_, address[] tokenManagerImplementations) public
```

_All of the variables passed here are stored as immutable variables._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployer_ | address | the address of the TokenManagerDeployer. |
| interchainTokenDeployer_ | address | the address of the InterchainTokenDeployer. |
| gateway_ | address | the address of the AxelarGateway. |
| gasService_ | address | the address of the AxelarGasService. |
| interchainRouter_ | address | the address of the InterchainAddressTracker. |
| tokenManagerImplementations | address[] | this needs to have implementations in the order: Mint-burn, Mint-burn from, Lock-unlock, and Lock-unlock with fee. |

### onlyRemoteService

```solidity
modifier onlyRemoteService(string sourceChain, string sourceAddress)
```

This modifier is used to ensure that only a remote InterchainTokenService can _execute this one.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the source of the contract call. |
| sourceAddress | string | the address that the call came from. |

### onlyTokenManager

```solidity
modifier onlyTokenManager(bytes32 tokenId)
```

This modifier is used to ensure certain functions can only be called by TokenManagers.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the `tokenId` of the TokenManager trying to perform the call. |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### tokenManagerAddress

```solidity
function tokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_)
```

Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | deployment address of the TokenManager. |

### validTokenManagerAddress

```solidity
function validTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_)
```

Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress_ | address | deployment address of the TokenManager. |

### tokenAddress

```solidity
function tokenAddress(bytes32 tokenId) external view returns (address tokenAddress_)
```

Returns the address of the token that an existing tokenManager points to.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | the address of the token. |

### interchainTokenAddress

```solidity
function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress_)
```

Returns the address of the interchain token that would be deployed with a given tokenId.
The token does not need to exist.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | the address of the interchain token. |

### interchainTokenId

```solidity
function interchainTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
This will not depend on what chain it is called from, unlike canonical tokenIds.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the address of the TokenManager deployer. |
| salt | bytes32 | the salt that the deployer uses for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId that the custom TokenManager would get (or has gotten). |

### tokenManagerImplementation

```solidity
function tokenManagerImplementation(uint256 tokenManagerType) external view returns (address)
```

Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
to figure out their implementations

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | the type of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | tokenManagerAddress the address of the TokenManagerImplementation. |

### flowLimit

```solidity
function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_)
```

Getter function for the flow limit of an existing token manager with a give token ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | the flow limit. |

### flowOutAmount

```solidity
function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_)
```

Getter function for the flow out amount of an existing token manager with a give token ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | the flow out amount. |

### flowInAmount

```solidity
function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_)
```

Getter function for the flow in amount of an existing token manager with a give token ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | the flow in amount. |

### deployTokenManager

```solidity
function deployTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Used to deploy remote custom TokenManagers.

_`gasValue` exists because this function can be part of a multicall involving multiple functions
that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| destinationChain | string | the name of the chain to deploy the TokenManager and interchain token to. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | the type of TokenManager to be deployed. |
| params | bytes | the params that will be used to initialize the TokenManager. |
| gasValue | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string destinationChain, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, uint256 gasValue) external payable
```

Used to deploy a interchain token alongside a TokenManager in another chain. If the `distributor` is empty
bytes then a mint/burn TokenManager is used. Otherwise a lock/unlock TokenManager is used.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| destinationChain | string | the name of the destination chain to deploy to. |
| name | string | the name of the token to be deployed. |
| symbol | string | the symbol of the token to be deployed. |
| decimals | uint8 | the decimals of the token to be deployed. |
| distributor | bytes | the address that will be able to mint and burn the deployed token. |
| operator | bytes |  |
| gasValue | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### contractCallValue

```solidity
function contractCallValue(string sourceChain, string sourceAddress, bytes payload) public view virtual returns (address, uint256)
```

_Returns the value (token address and amount) associated with a contract call_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | The source blockchain. |
| sourceAddress | string | The source address. |
| payload | bytes | The payload data. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |
| [1] | uint256 |  |

### expressExecute

```solidity
function expressExecute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) external payable
```

Express executes a contract call.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 | The commandId for the contractCall. |
| sourceChain | string | The source chain. |
| sourceAddress | string | The source address. |
| payload | bytes | The payload data. |

### _expressExecute

```solidity
function _expressExecute(string sourceChain, bytes payload) internal
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
interchainTransfer that matches the parameters passed here.

_This is not to be used with fee on transfer tokens as it will incur losses for the express caller._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the name of the chain where the interchainTransfer originated from. |
| payload | bytes | the payload of the receive token |

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transfer a token interchain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId for the token link. |
| destinationChain | string | the name of the chain to send the token to. |
| destinationAddress | bytes | the recipient of the interchain transfer. |
| amount | uint256 | the amount of token to give. |
| metadata | bytes | the data to be passed to the destination. If provided with a bytes4(0) prefix, it'll execute the destination contract. |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit a callContractWithInterchainToken for the given tokenId. Only callable by a token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | the address where the token is coming from, which will also be used for reimbursement of gas. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the destinationAddress for the interchainTransfer. |
| amount | uint256 | the amount of token to give. |
| metadata | bytes | the data to be passed to the destination. |

### setFlowLimits

```solidity
function setFlowLimits(bytes32[] tokenIds, uint256[] flowLimits) external
```

Used to set a flow limit for a token manager that has the service as its operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenIds | bytes32[] | an array of the token Ids of the tokenManagers to set the flow limit of. |
| flowLimits | uint256[] | the flowLimits to set |

### setPauseStatus

```solidity
function setPauseStatus(bool paused) external
```

Used to pause the entire service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | what value to set paused to. |

### _setup

```solidity
function _setup(bytes params) internal
```

### _sanitizeTokenManagerImplementation

```solidity
function _sanitizeTokenManagerImplementation(address[] tokenManagerImplementations, enum ITokenManagerType.TokenManagerType tokenManagerType) internal pure returns (address implementation_)
```

### execute

```solidity
function execute(bytes32 commandId, string sourceChain, string sourceAddress, bytes payload) external
```

Executes operations based on the payload and messageType.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commandId | bytes32 |  |
| sourceChain | string | The chain where the transaction originates from |
| sourceAddress | string | The address of the remote ITS where the transaction originates from |
| payload | bytes | The encoded data payload for the transaction |

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

### _processReceiveTokenPayload

```solidity
function _processReceiveTokenPayload(address expressExecutor, string sourceChain, bytes payload, uint256 messageType) internal
```

Processes the payload data for a send token call

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| expressExecutor | address |  |
| sourceChain | string | The chain where the transaction originates from |
| payload | bytes | The encoded data payload to be processed |
| messageType | uint256 |  |

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

Process a deploy interchain token and manager payload.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| payload | bytes | The encoded data payload to be processed |

### _callContract

```solidity
function _callContract(string destinationChain, bytes payload, uint256 gasValue) internal
```

Calls a contract on a specific destination chain with the given payload

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The target chain where the contract will be called |
| payload | bytes | The data payload for the transaction |
| gasValue | uint256 | The amount of gas to be paid for the transaction |

### _validateToken

```solidity
function _validateToken(address tokenAddress_) internal view returns (string name, string symbol, uint8 decimals)
```

### _deployRemoteTokenManager

```solidity
function _deployRemoteTokenManager(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager on a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token |
| destinationChain | string | The chain where the token manager will be deployed |
| gasValue | uint256 | The amount of gas to be paid for the transaction |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager to be deployed |
| params | bytes | Additional parameters for the token manager deployment |

### _deployRemoteInterchainToken

```solidity
function _deployRemoteInterchainToken(bytes32 tokenId, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue) internal
```

Deploys a interchain token on a destination chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token |
| name | string | The name of the token |
| symbol | string | The symbol of the token |
| decimals | uint8 | The number of decimals of the token |
| distributor | bytes | The distributor address for the token |
| operator | bytes |  |
| destinationChain | string | The destination chain where the token will be deployed |
| gasValue | uint256 | The amount of gas to be paid for the transaction |

### _deployTokenManager

```solidity
function _deployTokenManager(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to be deployed |
| params | bytes | Additional parameters for the token manager deployment |

### _getInterchainTokenSalt

```solidity
function _getInterchainTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt)
```

Compute the salt for a interchain token deployment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The computed salt for the token deployment |

### _deployInterchainToken

```solidity
function _deployInterchainToken(bytes32 tokenId, bytes distributorBytes, string name, string symbol, uint8 decimals) internal returns (address tokenAddress_)
```

Deploys a interchain token.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The ID of the token |
| distributorBytes | bytes | The distributor address for the token |
| name | string | The name of the token |
| symbol | string | The symbol of the token |
| decimals | uint8 | The number of decimals of the token |

### _decodeMetadata

```solidity
function _decodeMetadata(bytes metadata) internal pure returns (uint32 version, bytes data)
```

### _transmitInterchainTransfer

```solidity
function _transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) internal
```

Transmit a callContractWithInterchainToken for the given tokenId. Only callable by a token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | the address where the token is coming from, which will also be used for reimburment of gas. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the destinationAddress for the interchainTransfer. |
| amount | uint256 | the amount of token to give. |
| metadata | bytes | the data to be passed to the destiantion. |

## IDistributable

### transferDistributorship

```solidity
function transferDistributorship(address distributor_) external
```

Change the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor_ | address | The address of the new distributor |

### proposeDistributorship

```solidity
function proposeDistributorship(address distributor_) external
```

Proposed a change of the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor_ | address | The address of the new distributor |

### acceptDistributorship

```solidity
function acceptDistributorship(address fromDistributor) external
```

Accept a change of the distributor of the contract

_Can only be called by the proposed distributor_

### isDistributor

```solidity
function isDistributor(address addr) external view returns (bool)
```

Query if an address is a distributor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

## IERC20BurnableFrom

_Interface of the ERC20 standard as defined in the EIP._

### burnFrom

```solidity
function burnFrom(address from, uint256 amount) external
```

Function to burn tokens
Requires the caller to have allowance for `amount` on `from`

_Can only be called by the distributor address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt |
| amount | uint256 | The amount of tokens to burn |

## IERC20MintableBurnable

_Interface of the ERC20 standard as defined in the EIP._

### mint

```solidity
function mint(address to, uint256 amount) external
```

Function to mint new tokens

_Can only be called by the distributor address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address that will receive the minted tokens |
| amount | uint256 | The amount of tokens to mint |

### burn

```solidity
function burn(address from, uint256 amount) external
```

Function to burn tokens

_Can only be called by the distributor address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address that will have its tokens burnt |
| amount | uint256 | The amount of tokens to burn |

## IERC20Named

_Interface of the ERC20 standard as defined in the EIP._

### name

```solidity
function name() external view returns (string)
```

Getter for the name of the token

### symbol

```solidity
function symbol() external view returns (string)
```

Getter for the symbol of the token

### decimals

```solidity
function decimals() external view returns (uint8)
```

Getter for the decimals of the token

## IFlowLimit

### FlowLimitExceeded

```solidity
error FlowLimitExceeded(uint256 limit, uint256 flowAmount)
```

### FlowLimitSet

```solidity
event FlowLimitSet(bytes32 tokenId, address operator, uint256 flowLimit_)
```

### flowLimit

```solidity
function flowLimit() external view returns (uint256 flowLimit_)
```

Returns the current flow limit

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value |

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount |

## IImplementation

### NotProxy

```solidity
error NotProxy()
```

### setup

```solidity
function setup(bytes params) external
```

Called by the proxy to setup itself.

_This should be hidden by the proxy._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the data to be used for the initialization. |

## IInterchainToken

_Interface of the ERC20 standard as defined in the EIP._

### tokenManager

```solidity
function tokenManager() external view returns (contract ITokenManager tokenManager_)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager_ | contract ITokenManager | the TokenManager called to facilitate cross chain transfers. |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | the string representation of the destination chain. |
| recipient | bytes | the bytes representation of the address of the recipient. |
| amount | uint256 | the amount of token to be transferred. |
| metadata | bytes | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

## IInterchainTokenDeployer

This contract is used to deploy new instances of the StandardizedTokenProxy contract.

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

Returns the standardized token implementation address

### deployedAddress

```solidity
function deployedAddress(bytes32 salt) external view returns (address tokenAddress)
```

Returns the standardized token deployment address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the token address. |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals) external payable returns (address tokenAddress)
```

Deploys a new instance of the StandardizedTokenProxy contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used by Create3Deployer |
| tokenManager | address | Address of the token manager |
| distributor | address | Address of the distributor |
| name | string | Name of the token |
| symbol | string | Symbol of the token |
| decimals | uint8 | Decimals of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of the deployed token |

## IInterchainTokenExecutable

Implement this to accept calls from the InterchainTokenService.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

This will be called after the tokens arrive to this contract

_Executable should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the name of the source chain |
| sourceAddress | bytes | the address that sent the contract call |
| data | bytes | the data to be processed |
| tokenId | bytes32 | the tokenId of the token manager managing the token. |
| token | address | the address of the token. |
| amount | uint256 | the amount of token that was sent |

## IInterchainTokenExpressExecutable

Implement this to accept express calls from the InterchainTokenService.

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external returns (bytes32)
```

This will be called after the tokens arrive to this contract

_Executable should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the name of the source chain |
| sourceAddress | bytes | the address that sent the contract call |
| data | bytes | the data to be processed |
| tokenId | bytes32 | the token id of the token manager managing the token. |
| token | address | the address of the token. |
| amount | uint256 | the amount of token that was sent |

## IInterchainTokenService

### ZeroAddress

```solidity
error ZeroAddress()
```

### LengthMismatch

```solidity
error LengthMismatch()
```

### InvalidTokenManagerImplementationType

```solidity
error InvalidTokenManagerImplementationType(address implementation)
```

### NotRemoteService

```solidity
error NotRemoteService()
```

### TokenManagerDoesNotExist

```solidity
error TokenManagerDoesNotExist(bytes32 tokenId)
```

### NotTokenManager

```solidity
error NotTokenManager(address caller, address tokenManager)
```

### ExecuteWithInterchainTokenFailed

```solidity
error ExecuteWithInterchainTokenFailed(address contractAddress)
```

### InvalidCanonicalTokenId

```solidity
error InvalidCanonicalTokenId(bytes32 expectedCanonicalTokenId)
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

### UntrustedChain

```solidity
error UntrustedChain(string chainName)
```

### InvalidExpressMessageType

```solidity
error InvalidExpressMessageType(uint256 messageType)
```

### TokenSent

```solidity
event TokenSent(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount)
```

### TokenSentWithData

```solidity
event TokenSentWithData(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, address sourceAddress, bytes data)
```

### TokenReceived

```solidity
event TokenReceived(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount)
```

### TokenReceivedWithData

```solidity
event TokenReceivedWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount)
```

### TokenManagerDeploymentStarted

```solidity
event TokenManagerDeploymentStarted(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeploymentStarted

```solidity
event InterchainTokenDeploymentStarted(bytes32 tokenId, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue)
```

### TokenManagerDeployed

```solidity
event TokenManagerDeployed(bytes32 tokenId, address tokenManager, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### InterchainTokenDeployed

```solidity
event InterchainTokenDeployed(bytes32 tokenId, address tokenAddress, address distributor, string name, string symbol, uint8 decimals)
```

### InterchainTokenIdClaimed

```solidity
event InterchainTokenIdClaimed(bytes32 tokenId, address deployer, bytes32 salt)
```

### PausedSet

```solidity
event PausedSet(bool paused, address msgSender)
```

### interchainAddressTracker

```solidity
function interchainAddressTracker() external view returns (contract IInterchainAddressTracker interchainAddressTracker_)
```

Returns the address of the interchain router contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainAddressTracker_ | contract IInterchainAddressTracker | The interchainAddressTracker. |

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

Returns the address of the standardized token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenDeployerAddress | address | The address of the standardized token deployer contract. |

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

### tokenAddress

```solidity
function tokenAddress(bytes32 tokenId) external view returns (address tokenAddress_)
```

Returns the address of the token associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the token. |

### interchainTokenAddress

```solidity
function interchainTokenAddress(bytes32 tokenId) external view returns (address tokenAddress_)
```

Returns the address of the standardized token associated with the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the standardized token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the standardized token. |

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

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string destinationChain, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, uint256 gasValue) external payable
```

Deploys and registers a standardized token on a remote chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used for token deployment. |
| destinationChain | string | The name of the destination chain. Use '' for this chain. |
| name | string | The name of the standardized tokens. |
| symbol | string | The symbol of the standardized tokens. |
| decimals | uint8 | The number of decimals for the standardized tokens. |
| distributor | bytes | The distributor data for mint/burn operations. |
| operator | bytes |  |
| gasValue | uint256 | The gas value for deployment. |

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

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Initiates an interchain token transfer. Only callable by TokenManagers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The tokenId of the token to be transmitted. |
| sourceAddress | address | The source address of the token. |
| destinationChain | string | The name of the destination chain. |
| destinationAddress | bytes | The destination address on the destination chain. |
| amount | uint256 | The amount of tokens to transmit. |
| metadata | bytes | The metadata associated with the transmission. |

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

Sets the paused state of the contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | The boolean value indicating whether the contract is paused or not. |

## IOperatable

### transferOperatorship

```solidity
function transferOperatorship(address operator_) external
```

Change the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator |

### proposeOperatorship

```solidity
function proposeOperatorship(address operator_) external
```

Proposed a change of the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator |

### acceptOperatorship

```solidity
function acceptOperatorship(address fromOperator) external
```

Accept a proposed change of operatorship

_Can only be called by the proposed operator_

### isOperator

```solidity
function isOperator(address addr) external view returns (bool)
```

Query if an address is a operator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

## IStandardizedToken

This contract implements a standardized token which extends InterchainToken functionality.
This contract also inherits Distributable and Implementation logic.

### TokenManagerAddressZero

```solidity
error TokenManagerAddressZero()
```

### TokenNameEmpty

```solidity
error TokenNameEmpty()
```

### setup

```solidity
function setup(bytes params) external
```

Called by the proxy to setup itself.

_This should be hidden by the proxy._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the data to be used for the initialization. |

### tokenManager

```solidity
function tokenManager() external view returns (contract ITokenManager tokenManager_)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager_ | contract ITokenManager | the TokenManager called to facilitate cross chain transfers. |

## ITokenManager

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

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

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| metadata | bytes | any additional data to be sent with the transfer. |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| data | bytes | the data to pass to the destination contract. |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the address of the user paying for the cross chain transfer. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| metadata | bytes | any additional data to be sent with the transfer. |

### giveToken

```solidity
function giveToken(address destinationAddress, uint256 amount) external returns (uint256)
```

This function gives token to a specified address. Can only be called by the service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationAddress | address | the address to give tokens to. |
| amount | uint256 | the amount of token to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee. |

### takeToken

```solidity
function takeToken(address sourceAddress, uint256 amount) external returns (uint256)
```

This function takes token to from a specified address. Can only be called by the service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceAddress | address | the address to take tokens from. |
| amount | uint256 | the amount of token to take. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of token actually taken, which will onle be differen than `amount` in cases where the token takes some on-transfer fee. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit_) external
```

This function sets the flow limit for this TokenManager. Can only be called by the operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | the maximum difference between the tokens flowing in and/or out at any given interval of time (6h) |

## ITokenManagerDeployer

This contract is used to deploy new instances of the TokenManagerProxy contract.

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
| tokenManager | address | Address of the deployed tokenManager |

## ITokenManagerLiquidityPool

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### params

```solidity
function params(bytes operator_, address tokenAddress_, address liquidityPool_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |
| liquidityPool_ | address | he address of the liquidity pool. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

### liquidityPool

```solidity
function liquidityPool() external view returns (address liquidityPool_)
```

_Reads the stored liquidity pool address from the specified storage slot_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidityPool_ | address | The address of the liquidity pool |

### setLiquidityPool

```solidity
function setLiquidityPool(address newLiquidityPool) external
```

_Updates the address of the liquidity pool. Can only be called by the operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newLiquidityPool | address | The new address of the liquidity pool |

## ITokenManagerLockUnlock

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## ITokenManagerMintBurn

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## ITokenManagerProxy

_This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
inherits from FixedProxy from the gmp sdk repo_

### ImplementationLookupFailed

```solidity
error ImplementationLookupFailed()
```

### SetupFailed

```solidity
error SetupFailed(bytes returnData)
```

### NativeTokenNotAccepted

```solidity
error NativeTokenNotAccepted()
```

### implementationType

```solidity
function implementationType() external view returns (uint256)
```

Returns implementation type of this token manager

### implementation

```solidity
function implementation() external view returns (address)
```

Returns the address of the current implementation.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | impl The address of the current implementation |

### interchainTokenId

```solidity
function interchainTokenId() external view returns (bytes32)
```

Returns token ID of the token manager.

## ITokenManagerType

A simple interface that defines all the token manager types

### TokenManagerType

```solidity
enum TokenManagerType {
  MINT_BURN,
  MINT_BURN_FROM,
  LOCK_UNLOCK,
  LOCK_UNLOCK_FEE
}
```

## ITokenRegistrar

### ZeroAddress

```solidity
error ZeroAddress()
```

### NotDistributor

```solidity
error NotDistributor(address distributor)
```

### NotOperator

```solidity
error NotOperator(address operator)
```

### NonZeroMintAmount

```solidity
error NonZeroMintAmount()
```

### ApproveFailed

```solidity
error ApproveFailed()
```

### chainNameHash

```solidity
function chainNameHash() external view returns (bytes32)
```

### standardizedTokenSalt

```solidity
function standardizedTokenSalt(bytes32 chainAddressHash_, address deployer, bytes32 salt) external view returns (bytes32)
```

### standardizedTokenId

```solidity
function standardizedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId)
```

### interchainTokenAddress

```solidity
function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress)
```

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor, address operator) external payable
```

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address additionalDistributor, address optionalOperator, string destinationChain, uint256 gasValue) external payable
```

### canonicalTokenSalt

```solidity
function canonicalTokenSalt(bytes32 chainAddressHash_, address tokenAddress) external view returns (bytes32 salt)
```

### canonicalTokenId

```solidity
function canonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId)
```

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(string originalChainName, address originalAddress, string destinationChain, uint256 gasValue) external payable
```

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, uint256 gasValue) external payable
```

### interchainTransferFrom

```solidity
function interchainTransferFrom(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, uint256 gasValue) external payable
```

## TokenManagerProxy

This contract is a proxy for token manager contracts.

_It implements ITokenManagerProxy._

### interchainTokenService

```solidity
contract IInterchainTokenService interchainTokenService
```

### implementationType

```solidity
uint256 implementationType
```

Returns implementation type of this token manager

### interchainTokenId

```solidity
bytes32 interchainTokenId
```

Returns token ID of the token manager.

### constructor

```solidity
constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId, bytes params) public
```

_Constructs the TokenManagerProxy contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenServiceAddress_ | address | The address of the interchain token service |
| implementationType_ | uint256 | The token manager type |
| tokenId | bytes32 | The identifier for the token |
| params | bytes | The initialization parameters for the token manager contract |

### implementation

```solidity
function implementation() public view returns (address impl)
```

_Returns the address of the current implementation._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| impl | address | The address of the current implementation |

### _tokenManagerImplementation

```solidity
function _tokenManagerImplementation(contract IInterchainTokenService interchainTokenServiceAddress_, uint256 implementationType_) internal view returns (address impl)
```

_Returns the implementation address from the interchain token service for the provided type._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenServiceAddress_ | contract IInterchainTokenService | The address of the interchain token service |
| implementationType_ | uint256 | The token manager type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| impl | address | The address of the implementation |

### setup

```solidity
function setup(bytes setupParams) external
```

_Setup function. Empty in this contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| setupParams | bytes | Initialization parameters |

### receive

```solidity
receive() external payable virtual
```

_Reverts if native token is sent._

### fallback

```solidity
fallback() external payable virtual
```

_Fallback function. Delegates the call to the token manager contract._

## Invalid

```solidity
error Invalid()
```

## TestTokenManager

### NAME

```solidity
string NAME
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

## TestDistributable

### NAME

```solidity
string NAME
```

### constructor

```solidity
constructor() public
```

## TestFlowLimit

### NAME

```solidity
string NAME
```

### constructor

```solidity
constructor() public
```

## TestOperatable

### NAME

```solidity
string NAME
```

### constructor

```solidity
constructor() public
```

## TokenManager

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### interchainTokenService

```solidity
contract IInterchainTokenService interchainTokenService
```

### TOKEN_ADDRESS_SLOT

```solidity
uint256 TOKEN_ADDRESS_SLOT
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

Constructs the TokenManager contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service |

### onlyService

```solidity
modifier onlyService()
```

_A modifier that allows only the interchain token service to execute the function._

### onlyToken

```solidity
modifier onlyToken()
```

_A modifier that allows only the token to execute the function._

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address tokenAddress_)
```

_Reads the stored token address from the predetermined storage slot_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the token |

### interchainTokenId

```solidity
function interchainTokenId() public view returns (bytes32)
```

A function that returns the token id.

_This will only work when implementation is called by a proxy, which stores the tokenId as an immutable._

### setup

```solidity
function setup(bytes params) external
```

_This function should only be called by the proxy, and only once from the proxy constructor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the parameters to be used to initialize the TokenManager. The exact format depends on the type of TokenManager used but the first 32 bytes are reserved for the address of the operator, stored as bytes (to be compatible with non-EVM chains) |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable virtual
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| metadata | bytes | any additional data to be sent with the transfer. |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable virtual
```

Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| data | bytes | the data to pass to the destination contract. |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable virtual
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the address of the user paying for the cross chain transfer. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| metadata | bytes | any additional data to be sent with the transfer |

### giveToken

```solidity
function giveToken(address destinationAddress, uint256 amount) external returns (uint256)
```

This function gives token to a specified address. Can only be called by the service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationAddress | address | the address to give tokens to. |
| amount | uint256 | the amount of token to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee. |

### takeToken

```solidity
function takeToken(address sourceAddress, uint256 amount) external returns (uint256)
```

This function gives token to a specified address. Can only be called by the service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceAddress | address | the address to give tokens to. |
| amount | uint256 | the amount of token to give. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee. |

### addFlowLimiter

```solidity
function addFlowLimiter(address flowLimiter) external
```

This function adds a flow limiter for this TokenManager. Can only be called by the operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimiter | address | the address of the new flow limiter. |

### removeFlowLimiter

```solidity
function removeFlowLimiter(address flowLimiter) external
```

This function adds a flow limiter for this TokenManager. Can only be called by the operator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimiter | address | the address of the new flow limiter. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit_) external
```

This function sets the flow limit for this TokenManager. Can only be called by the flow limiters.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | the maximum difference between the tokens flowing in and/or out at any given interval of time (6h) |

### _setTokenAddress

```solidity
function _setTokenAddress(address tokenAddress_) internal
```

_Stores the token address in the predetermined storage slot_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress_ | address | The address of the token to store |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal virtual returns (uint256)
```

Transfers tokens from a specific address to this contract.
Must be overridden in the inheriting contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address from which the tokens will be sent |
| amount | uint256 | The amount of tokens to receive |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint amount of tokens received |

### _giveToken

```solidity
function _giveToken(address receiver, uint256 amount) internal virtual returns (uint256)
```

Transfers tokens from this contract to a specific address.
Must be overridden in the inheriting contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| receiver | address | The address to which the tokens will be sent |
| amount | uint256 | The amount of tokens to send |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint amount of tokens sent |

### _setup

```solidity
function _setup(bytes params) internal virtual
```

_Additional setup logic to perform
Must be overridden in the inheriting contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | The setup parameters |

## TokenManagerLiquidityPool

This contract is a an implementation of TokenManager that stores all tokens in a separate liquity pool
rather than within itself.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

### NotSupported

```solidity
error NotSupported()
```

### LIQUIDITY_POOL_SLOT

```solidity
uint256 LIQUIDITY_POOL_SLOT
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

_Constructs an instance of TokenManagerLiquidityPool. Calls the constructor
of TokenManagerAddressStorage which calls the constructor of TokenManager._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### _setup

```solidity
function _setup(bytes params_) internal
```

_Sets up the token address and liquidity pool address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The setup parameters in bytes. Should be encoded with the token address and the liquidity pool address. |

### _setLiquidityPool

```solidity
function _setLiquidityPool(address liquidityPool_) internal
```

_Stores the liquidity pool address at a specific storage slot_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidityPool_ | address | The address of the liquidity pool |

### liquidityPool

```solidity
function liquidityPool() public view returns (address liquidityPool_)
```

_Reads the stored liquidity pool address from the specified storage slot_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidityPool_ | address | The address of the liquidity pool |

### setLiquidityPool

```solidity
function setLiquidityPool(address newLiquidityPool) external
```

_Updates the address of the liquidity pool. Can only be called by the operator._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newLiquidityPool | address | The new address of the liquidity pool |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from a specified address to the liquidity pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address to transfer tokens from |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens. |

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from the liquidity pool to a specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to transfer tokens to |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred |

### params

```solidity
function params(bytes operator_, address tokenAddress_, address liquidityPoolAddress) external pure returns (bytes params_)
```

Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |
| liquidityPoolAddress | address | the liquidity pool to be used to store the bridged tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## TokenManagerLockUnlock

This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

### constructor

```solidity
constructor(address interchainTokenService_) public
```

_Constructs an instance of TokenManagerLockUnlock. Calls the constructor
of TokenManagerAddressStorage which calls the constructor of TokenManager._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### _setup

```solidity
function _setup(bytes params_) internal
```

_Sets up the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The setup parameters in bytes. Should be encoded with the token address. |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from a specified address to this contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address to transfer tokens from |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens. |

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from this contract to a specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to transfer tokens to |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred |

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## TokenManagerLockUnlockFee

This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

### constructor

```solidity
constructor(address interchainTokenService_) public
```

_Constructs an instance of TokenManagerLockUnlock. Calls the constructor
of TokenManagerAddressStorage which calls the constructor of TokenManager._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### _setup

```solidity
function _setup(bytes params_) internal
```

_Sets up the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The setup parameters in bytes. Should be encoded with the token address. |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from a specified address to this contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address to transfer tokens from |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens. |

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from this contract to a specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to transfer tokens to |
| amount | uint256 | The amount of tokens to transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint The actual amount of tokens transferred |

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## TokenManagerMintBurn

This contract is an implementation of TokenManager that mints and burns a specific token on behalf of the interchain token service.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

### constructor

```solidity
constructor(address interchainTokenService_) public
```

_Constructs an instance of TokenManagerMintBurn. Calls the constructor
of TokenManagerAddressStorage which calls the constructor of TokenManager._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure virtual returns (uint256)
```

A function that should return the implementation type of the token manager.

### _setup

```solidity
function _setup(bytes params_) internal
```

_Sets up the token address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | The setup parameters in bytes. Should be encoded with the token address. |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal virtual returns (uint256)
```

_Burns the specified amount of tokens from a particular address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | Address to burn tokens from |
| amount | uint256 | Amount of tokens to burn |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint Amount of tokens burned |

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Mints the specified amount of tokens to a particular address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Address to mint tokens to |
| amount | uint256 | Amount of tokens to mint |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint Amount of tokens minted |

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## TokenManagerMintBurnFrom

This contract is an implementation of TokenManager that mints and burns a specific token on behalf of the interchain token service.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

### constructor

```solidity
constructor(address interchainTokenService_) public
```

_Constructs an instance of TokenManagerMintBurn. Calls the constructor
of TokenManagerAddressStorage which calls the constructor of TokenManager._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Burns the specified amount of tokens from a particular address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | Address to burn tokens from |
| amount | uint256 | Amount of tokens to burn |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint Amount of tokens burned |

## TokenRegistrar

### NotApproved

```solidity
error NotApproved(address tokenAddress)
```

### service

```solidity
contract IInterchainTokenService service
```

### chainNameHash

```solidity
bytes32 chainNameHash
```

### PREFIX_CANONICAL_TOKEN_SALT

```solidity
bytes32 PREFIX_CANONICAL_TOKEN_SALT
```

### PREFIX_STANDARDIZED_TOKEN_SALT

```solidity
bytes32 PREFIX_STANDARDIZED_TOKEN_SALT
```

### constructor

```solidity
constructor(address interchainTokenServiceAddress) public
```

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### standardizedTokenSalt

```solidity
function standardizedTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) public pure returns (bytes32)
```

### standardizedTokenId

```solidity
function standardizedTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId)
```

### interchainTokenAddress

```solidity
function interchainTokenAddress(address deployer, bytes32 salt) public view returns (address tokenAddress)
```

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor, address operator) external payable
```

### deployRemoteInterchainToken

```solidity
function deployRemoteInterchainToken(string originalChainName, bytes32 salt, address additionalDistributor, address optionalOperator, string destinationChain, uint256 gasValue) external payable
```

### _deployInterchainToken

```solidity
function _deployInterchainToken(bytes32 salt, string destinationChain, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes distributor, bytes operator, uint256 gasValue) internal
```

### canonicalTokenSalt

```solidity
function canonicalTokenSalt(bytes32 chainNameHash_, address tokenAddress) public pure returns (bytes32 salt)
```

### canonicalTokenId

```solidity
function canonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId)
```

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(string originalChain, address originalTokenAddress, string destinationChain, uint256 gasValue) external payable
```

### interchainTransfer

```solidity
function interchainTransfer(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, uint256 gasValue) external payable
```

### interchainTransferFrom

```solidity
function interchainTransferFrom(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, uint256 gasValue) external payable
```

## Distributable

_A contract module which provides a basic access control mechanism, where
there is an account (a distributor) that can be granted exclusive access to
specific functions. This module is used through inheritance._

### _addDistributor

```solidity
function _addDistributor(address distributor_) internal
```

_Internal function that stores the new distributor address in the correct storage slot_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor_ | address | The address of the new distributor |

### transferDistributorship

```solidity
function transferDistributorship(address distributor_) external
```

Change the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor_ | address | The address of the new distributor |

### proposeDistributorship

```solidity
function proposeDistributorship(address distributor_) external
```

Proposed a change of the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| distributor_ | address | The address of the new distributor |

### acceptDistributorship

```solidity
function acceptDistributorship(address fromDistributor) external
```

Accept a change of the distributor of the contract

_Can only be called by the proposed distributor_

### isDistributor

```solidity
function isDistributor(address addr) external view returns (bool)
```

Query if an address is a distributor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

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

Returns the current flow limit

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value |

### _setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit_, bytes32 tokenId) internal
```

_Internal function to set the flow limit_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The value to set the flow limit to |
| tokenId | bytes32 |  |

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow out amount for a specific epoch_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow out amount for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow out amount from |

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow in amount for a specific epoch_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| epoch | uint256 | The epoch to get the flow in amount for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| slot | uint256 | The slot to get the flow in amount from |

### flowOutAmount

```solidity
function flowOutAmount() external view returns (uint256 flowOutAmount_)
```

Returns the current flow out amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount |

### _addFlow

```solidity
function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

_Adds a flow amount while ensuring it does not exceed the flow limit_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value |
| slotToAdd | uint256 | The slot to add the flow to |
| slotToCompare | uint256 | The slot to compare the flow against |
| flowAmount | uint256 | The flow amount to add |

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount_) internal
```

_Adds a flow out amount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The flow out amount to add |

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount_) internal
```

_Adds a flow in amount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The flow in amount to add |

## Implementation

This contract serves as a base for other contracts and enforces a proxy-first access restriction.

_Derived contracts must implement the setup function._

### constructor

```solidity
constructor() internal
```

_Contract constructor that sets the implementation address to the address of this contract._

### onlyProxy

```solidity
modifier onlyProxy()
```

_Modifier to require the caller to be the proxy contract.
Reverts if the caller is the current contract (i.e., the implementation contract itself)._

## Operatable

_A contract module which provides a basic access control mechanism, where
there is an account (a operator) that can be granted exclusive access to
specific functions. This module is used through inheritance._

### _addOperator

```solidity
function _addOperator(address operator_) internal
```

_Internal function that stores the new operator address in the correct storage slot_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator |

### transferOperatorship

```solidity
function transferOperatorship(address operator_) external
```

Change the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator |

### proposeOperatorship

```solidity
function proposeOperatorship(address operator_) external
```

Proposed a change of the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | address | The address of the new operator |

### acceptOperatorship

```solidity
function acceptOperatorship(address fromOperator) external
```

Accept a change of the operator of the contract

_Can only be called by the proposed operator_

### isOperator

```solidity
function isOperator(address addr) external view returns (bool)
```

Query if an address is an operator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address to query for |

## RolesConstants

### Roles

```solidity
enum Roles {
  DISTRIBUTOR,
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

## InterchainToken

The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists
that can be used to create approvals, and that `allowance` is a mapping.

### tokenManager

```solidity
function tokenManager() public view virtual returns (contract ITokenManager tokenManager_)
```

Getter for the tokenManager used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager_ | contract ITokenManager | the TokenManager called to facilitate cross chain transfers. |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | The destination chain identifier. |
| recipient | bytes | The bytes representation of the address of the recipient. |
| amount | uint256 | The amount of token to be transferred. |
| metadata | bytes | Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | the string representation of the destination chain. |
| recipient | bytes | the bytes representation of the address of the recipient. |
| amount | uint256 | the amount of token to be transferred. |
| metadata | bytes | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address from, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) internal virtual
```

A method to be overwritten that will be called before an interchain transfer. You can approve the tokenManager here if you need and want to, to allow users for a 1-call transfer in case of a lock-unlock token manager.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | the sender of the tokens. They need to have approved `msg.sender` before this is called. |
| destinationChain | string | the string representation of the destination chain. |
| destinationAddress | bytes | the bytes representation of the address of the recipient. |
| amount | uint256 | the amount of token to be transferred. |
| metadata | bytes | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

## ITokenManagerLockUnlockFee

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### params

```solidity
function params(bytes operator_, address tokenAddress_) external pure returns (bytes params_)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator_ | bytes | the operator of the TokenManager. |
| tokenAddress_ | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params_ | bytes | the resulting params to be passed to custom TokenManager deployments. |

## StandardizedTokenProxy

_Proxy contract for StandardizedToken contracts. Inherits from FixedProxy._

### constructor

```solidity
constructor(address implementationAddress, bytes params) public
```

_Constructs the StandardizedTokenProxy contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress | address | Address of the StandardizedToken implementation |
| params | bytes | Initialization parameters for the StandardizedToken contract |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

Getter for the contract id.

## FeeOnTransferTokenTest

### tokenManager_

```solidity
contract ITokenManager tokenManager_
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
constructor(string name_, string symbol_, uint8 decimals_, address tokenManagerAddress) public
```

### tokenManager

```solidity
function tokenManager() public view returns (contract ITokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager |  |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address sender, string, bytes, uint256 amount, bytes) internal
```

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

### setTokenManager

```solidity
function setTokenManager(contract ITokenManager tokenManagerAddress) external
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

## InterchainTokenTest

### tokenManager_

```solidity
contract ITokenManager tokenManager_
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
constructor(string name_, string symbol_, uint8 decimals_, address tokenManagerAddress) public
```

### tokenManager

```solidity
function tokenManager() public view returns (contract ITokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwritten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager |  |

### _beforeInterchainTransfer

```solidity
function _beforeInterchainTransfer(address sender, string, bytes, uint256 amount, bytes) internal
```

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

### setTokenManager

```solidity
function setTokenManager(contract ITokenManager tokenManagerAddress) external
```

## InvalidStandardizedToken

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

### tokenManager_

```solidity
address tokenManager_
```

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### tokenManager

```solidity
function tokenManager() public view returns (contract ITokenManager)
```

Returns the token manager for this token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager | ITokenManager The token manager contract |

### setup

```solidity
function setup(bytes params) external
```

Setup function to initialize contract parameters

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | The setup parameters in bytes The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo |

### mint

```solidity
function mint(address account, uint256 amount) external
```

Function to mint new tokens
Can only be called by the distributor address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will receive the minted tokens |
| amount | uint256 | The amount of tokens to mint |

### burn

```solidity
function burn(address account, uint256 amount) external
```

Function to burn tokens
Can only be called by the distributor address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will have its tokens burnt |
| amount | uint256 | The amount of tokens to burn |

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

## StandardizedToken

This contract implements a standardized token which extends InterchainToken functionality.
This contract also inherits Distributable and Implementation logic.

### name

```solidity
string name
```

Getter for the name of the token

### symbol

```solidity
string symbol
```

Getter for the symbol of the token

### decimals

```solidity
uint8 decimals
```

Getter for the decimals of the token

### tokenManager_

```solidity
address tokenManager_
```

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### tokenManager

```solidity
function tokenManager() public view returns (contract ITokenManager)
```

Returns the token manager for this token

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager | ITokenManager The token manager contract |

### setup

```solidity
function setup(bytes params) external
```

Setup function to initialize contract parameters

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | The setup parameters in bytes The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo |

### mint

```solidity
function mint(address account, uint256 amount) external
```

Function to mint new tokens
Can only be called by the distributor address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will receive the minted tokens |
| amount | uint256 | The amount of tokens to mint |

### burn

```solidity
function burn(address account, uint256 amount) external
```

Function to burn tokens
Can only be called by the distributor address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address that will have its tokens burnt |
| amount | uint256 | The amount of tokens to burn |

## InterchainTokenDeployer

This contract is used to deploy new instances of the StandardizedTokenProxy contract.

### implementationAddress

```solidity
address implementationAddress
```

Returns the standardized token implementation address

### constructor

```solidity
constructor(address implementationAddress_) public
```

Constructor for the InterchainTokenDeployer contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress_ | address | Address of the StandardizedToken contract |

### deployInterchainToken

```solidity
function deployInterchainToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals) external payable returns (address tokenAddress)
```

Deploys a new instance of the StandardizedTokenProxy contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | The salt used by Create3Deployer |
| tokenManager | address | Address of the token manager |
| distributor | address | Address of the distributor |
| name | string | Name of the token |
| symbol | string | Symbol of the token |
| decimals | uint8 | Decimals of the token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of the deployed token |

### deployedAddress

```solidity
function deployedAddress(bytes32 salt) external view returns (address tokenAddress)
```

Returns the standardized token deployment address.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the token address. |

## AddressTracker

### constructor

```solidity
constructor(address owner_, string chainName_, string[] trustedChainNames, string[] trustedAddresses) public
```

### setTrustedAddress

```solidity
function setTrustedAddress(string chain, string address_) external
```

_Sets the trusted address for the specified chain_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name to be trusted |
| address_ | string | Trusted address to be added for the chain |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

_Remove the trusted address of the chain._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name that should be made untrusted |

## InterchainTokenExecutable

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

### onlyService

```solidity
modifier onlyService()
```

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

This will be called after the tokens arrive to this contract

_Executable should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the name of the source chain |
| sourceAddress | bytes | the address that sent the contract call |
| data | bytes | the data to be processed |
| tokenId | bytes32 | the tokenId of the token manager managing the token. |
| token | address | the address of the token. |
| amount | uint256 | the amount of token that was sent |

### _executeWithInterchainToken

```solidity
function _executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal virtual
```

## InterchainTokenExpressExecutable

### EXPRESS_EXECUTE_SUCCESS

```solidity
bytes32 EXPRESS_EXECUTE_SUCCESS
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) external virtual returns (bytes32)
```

This will be called after the tokens arrive to this contract

_Executable should revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sourceChain | string | the name of the source chain |
| sourceAddress | bytes | the address that sent the contract call |
| data | bytes | the data to be processed |
| tokenId | bytes32 | the token id of the token manager managing the token. |
| token | address | the address of the token. |
| amount | uint256 | the amount of token that was sent |

## IAddressTracker

### setTrustedAddress

```solidity
function setTrustedAddress(string chain, string address_) external
```

_Sets the trusted address for the specified chain_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name to be trusted |
| address_ | string | Trusted address to be added for the chain |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

_Remove the trusted address of the chain._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chain | string | Chain name that should be made untrusted |

## IMockAxelarGateway

This interface is used for testing with an AxelarGateway that will arbitrarily approve calls.

### NotSelf

```solidity
error NotSelf()
```

### NotProxy

```solidity
error NotProxy()
```

### InvalidCodeHash

```solidity
error InvalidCodeHash()
```

### SetupFailed

```solidity
error SetupFailed()
```

### InvalidAuthModule

```solidity
error InvalidAuthModule()
```

### InvalidTokenDeployer

```solidity
error InvalidTokenDeployer()
```

### InvalidAmount

```solidity
error InvalidAmount()
```

### InvalidChainId

```solidity
error InvalidChainId()
```

### InvalidCommands

```solidity
error InvalidCommands()
```

### TokenDoesNotExist

```solidity
error TokenDoesNotExist(string symbol)
```

### TokenAlreadyExists

```solidity
error TokenAlreadyExists(string symbol)
```

### TokenDeployFailed

```solidity
error TokenDeployFailed(string symbol)
```

### TokenContractDoesNotExist

```solidity
error TokenContractDoesNotExist(address token)
```

### BurnFailed

```solidity
error BurnFailed(string symbol)
```

### MintFailed

```solidity
error MintFailed(string symbol)
```

### InvalidSetMintLimitsParams

```solidity
error InvalidSetMintLimitsParams()
```

### ExceedMintLimit

```solidity
error ExceedMintLimit(string symbol)
```

### TokenSent

```solidity
event TokenSent(address sender, string destinationChain, string destinationAddress, string symbol, uint256 amount)
```

### ContractCall

```solidity
event ContractCall(address sender, string destinationChain, string destinationContractAddress, bytes32 payloadHash, bytes payload)
```

### ContractCallWithToken

```solidity
event ContractCallWithToken(address sender, string destinationChain, string destinationContractAddress, bytes32 payloadHash, bytes payload, string symbol, uint256 amount)
```

### Executed

```solidity
event Executed(bytes32 commandId)
```

### TokenDeployed

```solidity
event TokenDeployed(string symbol, address tokenAddresses)
```

### ContractCallApproved

```solidity
event ContractCallApproved(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash, bytes32 sourceTxHash, uint256 sourceEventIndex)
```

### ContractCallApprovedWithMint

```solidity
event ContractCallApprovedWithMint(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash, string symbol, uint256 amount, bytes32 sourceTxHash, uint256 sourceEventIndex)
```

### TokenMintLimitUpdated

```solidity
event TokenMintLimitUpdated(string symbol, uint256 limit)
```

### OperatorshipTransferred

```solidity
event OperatorshipTransferred(bytes newOperatorsData)
```

### Upgraded

```solidity
event Upgraded(address implementation)
```

### callContract

```solidity
function callContract(string destinationChain, string contractAddress, bytes payload) external
```

### isContractCallApproved

```solidity
function isContractCallApproved(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash) external view returns (bool)
```

### validateContractCall

```solidity
function validateContractCall(bytes32 commandId, string sourceChain, string sourceAddress, bytes32 payloadHash) external returns (bool)
```

### setTokenAddress

```solidity
function setTokenAddress(string symbol, address tokenAddress) external
```

### approveContractCall

```solidity
function approveContractCall(bytes params, bytes32 commandId) external
```

### isCommandExecuted

```solidity
function isCommandExecuted(bytes32 commandId) external view returns (bool)
```

### tokenAddresses

```solidity
function tokenAddresses(string symbol) external view returns (address tokenAddress)
```

## IStandardizedTokenProxy

_Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy._

## CanonicalTokenRegistrarProxy

_Proxy contract for interchain token service contracts. Inherits from the Proxy contract._

### constructor

```solidity
constructor(address implementationAddress, address owner) public
```

_Constructs the InterchainTokenServiceProxy contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress | address | Address of the interchain token service implementation |
| owner | address | Address of the owner of the proxy |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

_Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 identifier for this contract |

## InterchainTokenServiceProxy

_Proxy contract for interchain token service contracts. Inherits from the FinalProxy contract._

### constructor

```solidity
constructor(address implementationAddress, address owner, address operator) public
```

_Constructs the InterchainTokenServiceProxy contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress | address | Address of the interchain token service implementation |
| owner | address | Address of the owner of the proxy |
| operator | address |  |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

_Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 identifier for this contract |

## TokenRegistrarProxy

_Proxy contract for interchain token service contracts. Inherits from the Proxy contract._

### constructor

```solidity
constructor(address implementationAddress, address owner) public
```

_Constructs the InterchainTokenServiceProxy contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| implementationAddress | address | Address of the interchain token service implementation |
| owner | address | Address of the owner of the proxy |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

_Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 identifier for this contract |

## InterchainExecutableTest

### MessageReceived

```solidity
event MessageReceived(string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount)
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
function _executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, address token, uint256 amount) internal
```

## DistributableTest

### nonce

```solidity
uint256 nonce
```

### constructor

```solidity
constructor(address distributor) public
```

### testDistributable

```solidity
function testDistributable() external
```

### distributorRole

```solidity
function distributorRole() external pure returns (uint8)
```

## FlowLimitTest

### TOKEN_ID

```solidity
bytes32 TOKEN_ID
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

## FlowLimitTestLiveNetwork

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

Returns the current flow limit

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit_ | uint256 | The current flow limit value |

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

Returns the current flow out amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowOutAmount_ | uint256 | The current flow out amount |

### flowInAmount

```solidity
function flowInAmount() external view returns (uint256 flowInAmount_)
```

Returns the current flow in amount

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowInAmount_ | uint256 | The current flow in amount |

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

## ImplementationTest

### val

```solidity
uint256 val
```

### setup

```solidity
function setup(bytes params) external
```

Called by the proxy to setup itself.

_This should be hidden by the proxy._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the data to be used for the initialization. |

## NakedProxy

### implementation

```solidity
address implementation
```

### constructor

```solidity
constructor(address implementation_) public
```

### fallback

```solidity
fallback() external payable virtual
```

### receive

```solidity
receive() external payable virtual
```

## OperatorableTest

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

