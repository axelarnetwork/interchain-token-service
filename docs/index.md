# Solidity API

## IAdminable

### NotAdmin

```solidity
error NotAdmin()
```

### admin

```solidity
function admin() external view returns (address admin_)
```

### setAdmin

```solidity
function setAdmin(address admin_) external
```

## IERC20BurnableMintable

_Interface of the ERC20 standard as defined in the EIP._

### mint

```solidity
function mint(address to, uint256 amount) external
```

### burn

```solidity
function burn(address from, uint256 amount) external
```

## IExpressCallHandler

### ExpressExecuted

```solidity
event ExpressExecuted(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash, address expressCaller)
```

### ExpressExecutionFulfilled

```solidity
event ExpressExecutionFulfilled(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash, address expressCaller)
```

### ExpressExecutedWithData

```solidity
event ExpressExecutedWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash, address expressCaller)
```

### ExpressExecutionWithDataFulfilled

```solidity
event ExpressExecutionWithDataFulfilled(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash, address expressCaller)
```

### getExpressSendToken

```solidity
function getExpressSendToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) external view returns (address expressCaller)
```

### getExpressSendTokenWithData

```solidity
function getExpressSendTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash) external view returns (address expressCaller)
```

## IFlowLimit

### FlowLimitExceeded

```solidity
error FlowLimitExceeded()
```

### getFlowLimit

```solidity
function getFlowLimit() external view returns (uint256 flowLimit)
```

### getFlowOutAmount

```solidity
function getFlowOutAmount() external view returns (uint256 flowOutAmount)
```

### getFlowInAmount

```solidity
function getFlowInAmount() external view returns (uint256 flowInAmount)
```

## IImplementation

### NotProxy

```solidity
error NotProxy()
```

## IInterchainTokenService

### ZeroAddress

```solidity
error ZeroAddress()
```

### LengthMismatch

```solidity
error LengthMismatch()
```

### NotRemoteService

```solidity
error NotRemoteService()
```

### TokenManagerNotDeployed

```solidity
error TokenManagerNotDeployed(bytes32 tokenId)
```

### NotTokenManager

```solidity
error NotTokenManager()
```

### ExecuteWithInterchainTokenFailed

```solidity
error ExecuteWithInterchainTokenFailed(address contractAddress)
```

### NotCanonicalTokenManager

```solidity
error NotCanonicalTokenManager()
```

### GatewayToken

```solidity
error GatewayToken()
```

### TokenManagerDeploymentFailed

```solidity
error TokenManagerDeploymentFailed()
```

### StandardizedTokenDeploymentFailed

```solidity
error StandardizedTokenDeploymentFailed()
```

### TokenSent

```solidity
event TokenSent(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, bytes32 sendHahs)
```

### TokenSentWithData

```solidity
event TokenSentWithData(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 amount, address sourceAddress, bytes data, bytes32 sendHash)
```

### TokenReceived

```solidity
event TokenReceived(bytes32 tokenId, string sourceChain, address destinationAddress, uint256 amount, bytes32 sendHash)
```

### TokenReceivedWithData

```solidity
event TokenReceivedWithData(bytes32 tokenId, string sourceChain, address destinationAddress, uint256 amount, bytes sourceAddress, bytes data, bytes32 sendHash)
```

### RemoteTokenManagerDeploymentInitialized

```solidity
event RemoteTokenManagerDeploymentInitialized(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### RemoteStandardizedTokenAndManagerDeploymentInitialized

```solidity
event RemoteStandardizedTokenAndManagerDeploymentInitialized(bytes32 tokenId, string destinationChain, uint256 gasValue)
```

### TokenManagerDeployed

```solidity
event TokenManagerDeployed(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### StandardizedTokenDeployed

```solidity
event StandardizedTokenDeployed(bytes32 tokenId, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo)
```

### tokenManagerDeployer

```solidity
function tokenManagerDeployer() external view returns (address)
```

### standardizedTokenDeployer

```solidity
function standardizedTokenDeployer() external view returns (address)
```

### getChainName

```solidity
function getChainName() external view returns (string name)
```

### getTokenManagerAddress

```solidity
function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress)
```

### getValidTokenManagerAddress

```solidity
function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress)
```

### getTokenAddress

```solidity
function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

### getStandardizedTokenAddress

```solidity
function getStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

### getCanonicalTokenId

```solidity
function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId)
```

### getCustomTokenId

```solidity
function getCustomTokenId(address admin, bytes32 salt) external view returns (bytes32 tokenId)
```

### getParamsLockUnlock

```solidity
function getParamsLockUnlock(bytes admin, address tokenAddress) external pure returns (bytes params)
```

### getParamsMintBurn

```solidity
function getParamsMintBurn(bytes admin, address tokenAddress) external pure returns (bytes params)
```

### getParamsLiquidityPool

```solidity
function getParamsLiquidityPool(bytes admin, address tokenAddress, address liquidityPoolAddress) external pure returns (bytes params)
```

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(bytes32 tokenId, string destinationChain, uint256 gasValue) external payable
```

### deployCustomTokenManager

```solidity
function deployCustomTokenManager(bytes32 salt, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) external payable
```

### deployRemoteCustomTokenManager

```solidity
function deployRemoteCustomTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable
```

### deployAndRegisterStandardizedToken

```solidity
function deployAndRegisterStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor) external payable
```

### deployAndRegisterRemoteStandardizedTokens

```solidity
function deployAndRegisterRemoteStandardizedTokens(bytes32 salt, string name, string symbol, uint8 decimals, bytes distributor, string destinationChain, uint256 gasValue) external payable
```

### getImplementation

```solidity
function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress)
```

### transmitSendToken

```solidity
function transmitSendToken(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

### transmitSendTokenWithData

```solidity
function transmitSendTokenWithData(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### transmitSendTokenWithToken

```solidity
function transmitSendTokenWithToken(bytes32 tokenId, string symbol, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

### transmitSendTokenWithDataWithToken

```solidity
function transmitSendTokenWithDataWithToken(bytes32 tokenId, string symbol, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### setFlowLimit

```solidity
function setFlowLimit(bytes32 tokenId, uint256 flowLimit) external
```

### setPaused

```solidity
function setPaused(bool paused) external
```

## IMulticall

### multicall

```solidity
function multicall(bytes[] data) external payable returns (bytes[] results)
```

## IPausable

### Paused

```solidity
error Paused()
```

## ITokenManager

### TokenLinkerZeroAddress

```solidity
error TokenLinkerZeroAddress()
```

### NotService

```solidity
error NotService()
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
error NotToken()
```

### tokenAddress

```solidity
function tokenAddress() external view returns (address)
```

### sendToken

```solidity
function sendToken(string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### sendSelf

```solidity
function sendSelf(address from, string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

### callContractWithSelf

```solidity
function callContractWithSelf(address from, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

### giveToken

```solidity
function giveToken(address destinationAddress, uint256 amount) external returns (uint256)
```

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit) external
```

## ITokenManagerDeployer

### AddressZero

```solidity
error AddressZero()
```

### TokenManagerDeploymentFailed

```solidity
error TokenManagerDeploymentFailed()
```

### deployer

```solidity
function deployer() external view returns (contract Create3Deployer)
```

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 tokenManagerType, bytes params) external payable
```

## ITokenManagerProxy

### ImplementationLookupFailed

```solidity
error ImplementationLookupFailed()
```

### SetupFailed

```solidity
error SetupFailed()
```

### implementationType

```solidity
function implementationType() external view returns (uint256)
```

### implementation

```solidity
function implementation() external view returns (address)
```

### tokenId

```solidity
function tokenId() external view returns (bytes32)
```

## ITokenManagerType

### TokenManagerType

```solidity
enum TokenManagerType {
  LOCK_UNLOCK,
  MINT_BURN,
  LIQUIDITY_POOL
}
```

## AddressBytesUtils

### toAddress

```solidity
function toAddress(bytes bytesAddress) internal pure returns (address addr)
```

### toBytes

```solidity
function toBytes(address addr) internal pure returns (bytes bytesAddress)
```

## TokenManager

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

### interchainTokenService

```solidity
contract IInterchainTokenService interchainTokenService
```

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interchainTokenService_ | address | The address of the interchain token service, which can be stored in an immutable variable saving some gas. |

### onlyService

```solidity
modifier onlyService()
```

### onlyToken

```solidity
modifier onlyToken()
```

### tokenAddress

```solidity
function tokenAddress() public view virtual returns (address)
```

### setup

```solidity
function setup(bytes params) external
```

_This is supposed to only be hidden by the proxy and only be called once from the proxy constructor_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the parameters to be used to initialize the TokenManager. The exact format depends on the type of TokenManager used but the first 32 bytes are reserved for the address of the admin, stored as bytes (to be compatible with non-EVM chains) |

### sendToken

```solidity
function sendToken(string destinationChain, bytes destinationAddress, uint256 amount) external payable virtual
```

Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable virtual
```

Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| data | bytes | the data to pass to the destination contract. |

### sendSelf

```solidity
function sendSelf(address sender, string destinationChain, bytes destinationAddress, uint256 amount) external payable virtual
```

Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the address of the user paying for the cross chain transfer. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |

### callContractWithSelf

```solidity
function callContractWithSelf(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable virtual
```

Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | the address of the user paying for the cross chain transfer. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the address of the user to send tokens to. |
| amount | uint256 | the amount of tokens to take from msg.sender. |
| data | bytes | the data to pass to the destination contract. |

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
| [0] | uint256 | the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit) external
```

This function sets the flow limit for this TokenManager. Can only be called by the admin.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| flowLimit | uint256 | the maximum difference between the tokens flowing in and/or out at any given interval of time (6h) |

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal virtual returns (uint256)
```

### _giveToken

```solidity
function _giveToken(address from, uint256 amount) internal virtual returns (uint256)
```

### _transmitSendToken

```solidity
function _transmitSendToken(address sender, string destinationChain, bytes destinationAddress, uint256 amount) internal virtual
```

### _transmitSendTokenWithData

```solidity
function _transmitSendTokenWithData(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) internal virtual
```

### _setup

```solidity
function _setup(bytes params) internal virtual
```

### _getTokenId

```solidity
function _getTokenId() internal view returns (bytes32 tokenId)
```

## TokenManagerAddressStorage

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

### TOKEN_ADDRESS_SLOT

```solidity
uint256 TOKEN_ADDRESS_SLOT
```

### tokenAddress

```solidity
function tokenAddress() public view returns (address tokenAddress_)
```

### _setTokenAddress

```solidity
function _setTokenAddress(address tokenAddress_) internal
```

## TokenManagerLiquidityPool

### LIQUIDITY_POOL_SLOT

```solidity
uint256 LIQUIDITY_POOL_SLOT
```

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### _setup

```solidity
function _setup(bytes params) internal
```

### _setLiquidityPool

```solidity
function _setLiquidityPool(address liquidityPool_) internal
```

### liquidityPool

```solidity
function liquidityPool() public view returns (address liquidityPool_)
```

### setLiquidityPool

```solidity
function setLiquidityPool(address newLiquidityPool) external
```

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

## TokenManagerLockUnlock

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### _setup

```solidity
function _setup(bytes params) internal
```

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

## TokenManagerMintBurn

### constructor

```solidity
constructor(address interchainTokenService_) public
```

### _setup

```solidity
function _setup(bytes params) internal
```

### _takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

### _giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

## Adminable

### ADMIN_SLOT

```solidity
uint256 ADMIN_SLOT
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### admin

```solidity
function admin() public view returns (address distr)
```

### _setAdmin

```solidity
function _setAdmin(address admin_) internal
```

### setAdmin

```solidity
function setAdmin(address admin_) external
```

## FlowLimit

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

### getFlowLimit

```solidity
function getFlowLimit() public view returns (uint256 flowLimit)
```

### _setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit) internal
```

### _getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

### _getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

### getFlowOutAmount

```solidity
function getFlowOutAmount() external view returns (uint256 flowOutAmount)
```

### getFlowInAmount

```solidity
function getFlowInAmount() external view returns (uint256 flowInAmount)
```

### _addFlow

```solidity
function _addFlow(uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

### _addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount) internal
```

### _addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount) internal
```

## Implementation

### constructor

```solidity
constructor() internal
```

### onlyProxy

```solidity
modifier onlyProxy()
```

### setup

```solidity
function setup(bytes params) external virtual
```

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

### implementationLiquidityPool

```solidity
address implementationLiquidityPool
```

### gasService

```solidity
contract IAxelarGasService gasService
```

### linkerRouter

```solidity
contract ILinkerRouter linkerRouter
```

### tokenManagerDeployer

```solidity
address tokenManagerDeployer
```

### standardizedTokenDeployer

```solidity
address standardizedTokenDeployer
```

### deployer

```solidity
contract Create3Deployer deployer
```

### chainNameHash

```solidity
bytes32 chainNameHash
```

### chainName

```solidity
bytes32 chainName
```

### PREFIX_CUSTOM_TOKEN_ID

```solidity
bytes32 PREFIX_CUSTOM_TOKEN_ID
```

### PREFIX_STANDARDIZED_TOKEN_ID

```solidity
bytes32 PREFIX_STANDARDIZED_TOKEN_ID
```

### PREFIX_STANDARDIZED_TOKEN_SALT

```solidity
bytes32 PREFIX_STANDARDIZED_TOKEN_SALT
```

### contractId

```solidity
bytes32 contractId
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address standardizedTokenDeployer_, address gateway_, address gasService_, address linkerRouter_, address[] tokenManagerImplementations, string chainName_) public
```

_All of the varaibles passed here are stored as immutable variables._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerDeployer_ | address | the address of the TokenManagerDeployer. |
| standardizedTokenDeployer_ | address | the address of the StandardizedTokenDeployer. |
| gateway_ | address | the address of the AxelarGateway. |
| gasService_ | address | the address of the AxelarGasService. |
| linkerRouter_ | address | the address of the LinkerRouter. |
| tokenManagerImplementations | address[] | this need to have exactly 3 implementations in the following order: Lock/Unlock, mint/burn and then liquidity pool. |
| chainName_ | string | the name of the current chain. |

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

### getChainName

```solidity
function getChainName() public view returns (string name)
```

Getter for the chain name.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | the name of the chain |

### getTokenManagerAddress

```solidity
function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress)
```

Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress | address | deployement address of the TokenManager. |

### getValidTokenManagerAddress

```solidity
function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress)
```

Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress | address | deployement address of the TokenManager. |

### getTokenAddress

```solidity
function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the address of the token. |

### getStandardizedTokenAddress

```solidity
function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the standardized token that would be deployed with a given tokenId. The token does not need to exist.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the address of the standardized token. |

### getCanonicalTokenId

```solidity
function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a canonical link for a given token. This will depend on what chain it is called from, unlike custom tokenIds.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the address of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId that the canonical TokenManager would get (or has gotten) for the token. |

### getCustomTokenId

```solidity
function getCustomTokenId(address admin, bytes32 salt) public pure returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt. This will not depend on what chain it is called from, unlike canonical tokenIds.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| admin | address | the address of the TokenManager deployer. |
| salt | bytes32 | the salt that the deployer uses for the deployment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId that the custom TokenManager would get (or has gotten). |

### getImplementation

```solidity
function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress)
```

Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies to figure out their implementations

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerType | uint256 | the type of the TokenManager. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManagerAddress | address | the address of the TokenManagerImplementation. |

### getParamsLockUnlock

```solidity
function getParamsLockUnlock(bytes admin, address tokenAddress) public pure returns (bytes params)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| admin | bytes | the admin of the TokenManager. |
| tokenAddress | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### getParamsMintBurn

```solidity
function getParamsMintBurn(bytes admin, address tokenAddress) public pure returns (bytes params)
```

Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| admin | bytes | the admin of the TokenManager. |
| tokenAddress | address | the token to be managed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### getParamsLiquidityPool

```solidity
function getParamsLiquidityPool(bytes admin, address tokenAddress, address liquidityPoolAddress) public pure returns (bytes params)
```

Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| admin | bytes | the admin of the TokenManager. |
| tokenAddress | address | the token to be managed. |
| liquidityPoolAddress | address | the liquidity pool to be used to store the bridged tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Used to register canonical tokens. Caller does not matter.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | the token to be bridged. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId that was used for this canonical token. |

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(bytes32 tokenId, string destinationChain, uint256 gasValue) public payable
```

Used to deploy remote TokenManagers and standardized tokens for a canonical token. This needs to be called from the chain that registered the canonical token, and anyone can call it.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the canonical token. |
| destinationChain | string | the name of the chain to deploy the TokenManager and standardized token to. |
| gasValue | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### deployCustomTokenManager

```solidity
function deployCustomTokenManager(bytes32 salt, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) public payable
```

Used to deploy custom TokenManagers with the specified salt. Different callers would result in different tokenIds.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | the type of TokenManager to be deployed. |
| params | bytes | the params that will be used to initialize the TokenManager. |

### deployRemoteCustomTokenManager

```solidity
function deployRemoteCustomTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable
```

Used to deploy remote custom TokenManagers.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| destinationChain | string | the name of the chain to deploy the TokenManager and standardized token to. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | the type of TokenManager to be deployed. |
| params | bytes | the params that will be used to initialize the TokenManager. |
| gasValue | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### deployAndRegisterStandardizedToken

```solidity
function deployAndRegisterStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor) public payable
```

Used to deploy a standardized token alongside a TokenManager. If the `distributor` is the address of the TokenManager (which can be calculated ahead of time) then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| name | string | the name of the token to be deployed. |
| symbol | string | the symbol of the token to be deployed. |
| decimals | uint8 | the decimals of the token to be deployed. |
| mintAmount | uint256 | the amount of token to be mint during deployment to msg.sender. |
| distributor | address | the address that will be able to mint and burn the deployed token. |

### deployAndRegisterRemoteStandardizedTokens

```solidity
function deployAndRegisterRemoteStandardizedTokens(bytes32 salt, string name, string symbol, uint8 decimals, bytes distributor, string destinationChain, uint256 gasValue) external payable
```

Used to deploy a standardized token alongside a TokenManager in another chain. If the `distributor` is empty bytes then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | the salt to be used. |
| name | string | the name of the token to be deployed. |
| symbol | string | the symbol of the token to be deployed. |
| decimals | uint8 | the decimals of the token to be deployed. |
| distributor | bytes | the address that will be able to mint and burn the deployed token. |
| destinationChain | string | the name of the destination chain to deploy to. |
| gasValue | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### expressReceiveToken

```solidity
function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) external
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager used. |
| destinationAddress | address | the destinationAddress for the sendToken. |
| amount | uint256 | the amount of token to give. |
| sendHash | bytes32 | the sendHash detected at the sourceChain. |

### expressReceiveTokenWithData

```solidity
function expressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash) external
```

Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager used. |
| sourceChain | string | the name of the chain where the call came from. |
| sourceAddress | bytes | the caller of callContractWithInterchainToken. |
| destinationAddress | address | the destinationAddress for the sendToken. |
| amount | uint256 | the amount of token to give. |
| data | bytes | the data to be passed to destinationAddress after giving them the tokens specified. |
| sendHash | bytes32 | the sendHash detected at the sourceChain. |

### transmitSendToken

```solidity
function transmitSendToken(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

Transmit a sendToken for the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | the address where the token is coming from, which will also be used for reimburment of gas. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the destinationAddress for the sendToken. |
| amount | uint256 | the amount of token to give. |

### transmitSendTokenWithData

```solidity
function transmitSendTokenWithData(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

Transmit a sendTokenWithData for the given tokenId.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the tokenId of the TokenManager (which must be the msg.sender). |
| sourceAddress | address | the address where the token is coming from, which will also be used for reimburment of gas. |
| destinationChain | string | the name of the chain to send tokens to. |
| destinationAddress | bytes | the destinationAddress for the sendToken. |
| amount | uint256 | the amount of token to give. |
| data | bytes | the data to be passed to the destiantion. |

### transmitSendTokenWithToken

```solidity
function transmitSendTokenWithToken(bytes32 tokenId, string symbol, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount) external payable
```

This is not currently used, it is meant for forward compatibility with gateway tokens.

### transmitSendTokenWithDataWithToken

```solidity
function transmitSendTokenWithDataWithToken(bytes32 tokenId, string symbol, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

This is not currently used, it is meant for forward compatibility with gateway tokens.

### setFlowLimit

```solidity
function setFlowLimit(bytes32 tokenId, uint256 flowLimit) external
```

Used to set a flow limit for a token manager that has the service as its admin.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | the token Id of the tokenManager to set the flow limit. |
| flowLimit | uint256 | the flowLimit to set |

### setPaused

```solidity
function setPaused(bool paused) external
```

Used to pause the entire service.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| paused | bool | what value to set paused to. |

### _execute

```solidity
function _execute(string sourceChain, string sourceAddress, bytes payload) internal
```

### _executeWithToken

```solidity
function _executeWithToken(string sourceChain, string sourceAddress, bytes payload, string, uint256) internal
```

### _processSendTokenPayload

```solidity
function _processSendTokenPayload(string sourceChain, bytes payload) internal
```

### _processSendTokenWithDataPayload

```solidity
function _processSendTokenWithDataPayload(string sourceChain, bytes payload) internal
```

### _processDeployTokenManagerPayload

```solidity
function _processDeployTokenManagerPayload(bytes payload) internal
```

### _processDeployStandardizedTokenAndManagerPayload

```solidity
function _processDeployStandardizedTokenAndManagerPayload(bytes payload) internal
```

### _callContract

```solidity
function _callContract(string destinationChain, bytes payload, uint256 gasValue, address refundTo) internal
```

### _callContractWithToken

```solidity
function _callContractWithToken(string destinationChain, string symbol, uint256 amount, bytes payload, address refundTo) internal
```

### _validateToken

```solidity
function _validateToken(address tokenAddress) internal returns (string name, string symbol, uint8 decimals)
```

### _deployRemoteTokenManager

```solidity
function _deployRemoteTokenManager(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

### _deployRemoteStandardizedToken

```solidity
function _deployRemoteStandardizedToken(bytes32 tokenId, string name, string symbol, uint8 decimals, bytes distributor, string destinationChain, uint256 gasValue) internal
```

### _passData

```solidity
function _passData(address destinationAddress, bytes32 tokenId, string sourceChain, bytes sourceAddress, uint256 amount, bytes data) internal
```

### _deployTokenManager

```solidity
function _deployTokenManager(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

### _getStandardizedTokenSalt

```solidity
function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt)
```

### _deployStandardizedToken

```solidity
function _deployStandardizedToken(bytes32 tokenId, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) internal
```

## IERC20Named

_Interface of the ERC20 standard as defined in the EIP._

### name

```solidity
function name() external returns (string)
```

### symbol

```solidity
function symbol() external returns (string)
```

### decimals

```solidity
function decimals() external returns (uint8)
```

## IInterchainTokenExecutable

### exectuteWithInterchainToken

```solidity
function exectuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

## ILinkerRouter

### ZeroAddress

```solidity
error ZeroAddress()
```

### LengthMismatch

```solidity
error LengthMismatch()
```

### ZeroStringLength

```solidity
error ZeroStringLength()
```

### validateSender

```solidity
function validateSender(string sourceChain, string sourceAddress) external view returns (bool)
```

### addTrustedAddress

```solidity
function addTrustedAddress(string sourceChain, string sourceAddress) external
```

### removeTrustedAddress

```solidity
function removeTrustedAddress(string sourceChain) external
```

### getRemoteAddress

```solidity
function getRemoteAddress(string chainName) external view returns (string remoteAddress)
```

### supportedByGateway

```solidity
function supportedByGateway(string chainName) external view returns (bool)
```

### addGatewaySupportedChains

```solidity
function addGatewaySupportedChains(string[] chainNames) external
```

### removeGatewaySupportedChains

```solidity
function removeGatewaySupportedChains(string[] chainNames) external
```

## IStandardizedTokenDeployer

### AddressZero

```solidity
error AddressZero()
```

### TokenDeploymentFailed

```solidity
error TokenDeploymentFailed()
```

### deployer

```solidity
function deployer() external view returns (contract Create3Deployer)
```

### deployStandardizedToken

```solidity
function deployStandardizedToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) external payable
```

## ExpressCallHandler

### PREFIX_EXPRESS_GIVE_TOKEN

```solidity
uint256 PREFIX_EXPRESS_GIVE_TOKEN
```

### PREFIX_EXPRESS_GIVE_TOKEN_WITH_DATA

```solidity
uint256 PREFIX_EXPRESS_GIVE_TOKEN_WITH_DATA
```

### _getExpressSendTokenSlot

```solidity
function _getExpressSendTokenSlot(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) internal pure returns (uint256 slot)
```

### _getExpressSendTokenWithDataSlot

```solidity
function _getExpressSendTokenWithDataSlot(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash) internal pure returns (uint256 slot)
```

### _setExpressSendToken

```solidity
function _setExpressSendToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash, address expressCaller) internal
```

### _setExpressSendTokenWithData

```solidity
function _setExpressSendTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash, address expressCaller) internal
```

### getExpressSendToken

```solidity
function getExpressSendToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) public view returns (address expressCaller)
```

### getExpressSendTokenWithData

```solidity
function getExpressSendTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash) public view returns (address expressCaller)
```

### _popExpressSendToken

```solidity
function _popExpressSendToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) internal returns (address expressCaller)
```

### _popExpressSendTokenWithData

```solidity
function _popExpressSendTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash) internal returns (address expressCaller)
```

## Multicall

### multicall

```solidity
function multicall(bytes[] data) public payable returns (bytes[] results)
```

## Pausable

### PAUSE_SLOT

```solidity
uint256 PAUSE_SLOT
```

### notPaused

```solidity
modifier notPaused()
```

### isPaused

```solidity
function isPaused() public view returns (bool paused)
```

### _setPaused

```solidity
function _setPaused(bool paused) internal
```

## InterchainToken

The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists that can be used to create approvals, and that `allowance` is a mapping.

_You can skip the `tokenManagerRequiresApproval()` function alltogether if you know what it should return for your token._

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

### getTokenManager

```solidity
function getTokenManager() public view virtual returns (contract ITokenManager tokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager | contract ITokenManager | the TokenManager called to facilitate cross chain transfers. |

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public view virtual returns (bool)
```

Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers. 
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20. 
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the TokenManager specifically to do it permissionlesly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

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
| destinationChain | string | the string representation of the destination chain. |
| recipient | bytes | the bytes representation of the address of the recipient. |
| amount | uint256 | the amount of token to be transfered. |
| metadata | bytes | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

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
| amount | uint256 | the amount of token to be transfered. |
| metadata | bytes | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

## IDistributable

### NotDistributor

```solidity
error NotDistributor()
```

### distributor

```solidity
function distributor() external view returns (address distributor)
```

### setDistributor

```solidity
function setDistributor(address distributor) external
```

## IInterchainToken

_Interface of the ERC20 standard as defined in the EIP._

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

## InterchainTokenTest

### tokenManager

```solidity
contract ITokenManager tokenManager
```

### tokenManagerRequiresApproval_

```solidity
bool tokenManagerRequiresApproval_
```

### constructor

```solidity
constructor(string name_, string symbol_, uint8 decimals_, address tokenManager_) public
```

### getTokenManager

```solidity
function getTokenManager() public view returns (contract ITokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager |  |

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public view returns (bool)
```

Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers. 
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20. 
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the TokenManager specifically to do it permissionlesly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

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
function setTokenManager(contract ITokenManager tokenManager_) external
```

## Distributable

### DISTRIBUTOR_SLOT

```solidity
uint256 DISTRIBUTOR_SLOT
```

### onlyDistributor

```solidity
modifier onlyDistributor()
```

### distributor

```solidity
function distributor() public view returns (address distr)
```

### _setDistributor

```solidity
function _setDistributor(address distributor_) internal
```

### setDistributor

```solidity
function setDistributor(address distr) external
```

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

### DOMAIN_SEPARATOR

```solidity
bytes32 DOMAIN_SEPARATOR
```

### nonces

```solidity
mapping(address => uint256) nonces
```

### _setDomainTypeSignatureHash

```solidity
function _setDomainTypeSignatureHash(string name) internal
```

### permit

```solidity
function permit(address issuer, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

## StandardizedToken

### tokenManager

```solidity
address tokenManager
```

### tokenManagerRequiresApproval_

```solidity
bool tokenManagerRequiresApproval_
```

### contractId

```solidity
bytes32 contractId
```

### getTokenManager

```solidity
function getTokenManager() public view returns (contract ITokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract ITokenManager |  |

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public view returns (bool)
```

Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers. 
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20. 
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the TokenManager specifically to do it permissionlesly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

### setup

```solidity
function setup(bytes params) external
```

### mint

```solidity
function mint(address account, uint256 amount) external
```

### burn

```solidity
function burn(address account, uint256 amount) external
```

## IStandardizedToken

### contractId

```solidity
function contractId() external view returns (bytes32)
```

### setup

```solidity
function setup(bytes params) external
```

## IStandardizedTokenProxy

### WrongImplementation

```solidity
error WrongImplementation()
```

### contractId

```solidity
function contractId() external view returns (bytes32)
```

## LinkerRouter

### remoteAddressHashes

```solidity
mapping(string => bytes32) remoteAddressHashes
```

### remoteAddresses

```solidity
mapping(string => string) remoteAddresses
```

### interchainTokenServiceAddress

```solidity
address interchainTokenServiceAddress
```

### interchainTokenServiceAddressHash

```solidity
bytes32 interchainTokenServiceAddressHash
```

### supportedByGateway

```solidity
mapping(string => bool) supportedByGateway
```

### contractId

```solidity
bytes32 contractId
```

### constructor

```solidity
constructor(address _interchainTokenServiceAddress, string[] trustedChainNames, string[] trustedAddresses) public
```

### _lowerCase

```solidity
function _lowerCase(string s) internal pure returns (string)
```

### validateSender

```solidity
function validateSender(string sourceChain, string sourceAddress) external view returns (bool)
```

### addTrustedAddress

```solidity
function addTrustedAddress(string chain, string addr) public
```

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

### addGatewaySupportedChains

```solidity
function addGatewaySupportedChains(string[] chainNames) external
```

### removeGatewaySupportedChains

```solidity
function removeGatewaySupportedChains(string[] chainNames) external
```

### getRemoteAddress

```solidity
function getRemoteAddress(string chainName) external view returns (string remoteAddress)
```

## InterchainTokenServiceProxy

### constructor

```solidity
constructor(address implementationAddress, address owner, bytes) public
```

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

## LinkerRouterProxy

### constructor

```solidity
constructor(address implementationAddress, address owner) public
```

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

## StandardizedTokenProxy

### contractId

```solidity
bytes32 contractId
```

### constructor

```solidity
constructor(address implementationAddress, bytes params) public
```

## TokenManagerProxy

### interchainTokenServiceAddress

```solidity
contract IInterchainTokenService interchainTokenServiceAddress
```

### implementationType

```solidity
uint256 implementationType
```

### tokenId

```solidity
bytes32 tokenId
```

### constructor

```solidity
constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId_, bytes params) public
```

### implementation

```solidity
function implementation() public view returns (address impl)
```

### _getImplementation

```solidity
function _getImplementation(contract IInterchainTokenService interchainTokenServiceAddress_, uint256 implementationType_) internal view returns (address impl)
```

### setup

```solidity
function setup(bytes setupParams) external
```

### fallback

```solidity
fallback() external payable virtual
```

### receive

```solidity
receive() external payable virtual
```

## GatewayToken

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

## InterchainExecutableTest

### MessageReceived

```solidity
event MessageReceived(string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount)
```

### lastMessage

```solidity
string lastMessage
```

### exectuteWithInterchainToken

```solidity
function exectuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

## MockAxelarGateway

### TokenType

```solidity
enum TokenType {
  InternalBurnable,
  InternalBurnableFrom,
  External
}
```

### KEY_IMPLEMENTATION

```solidity
bytes32 KEY_IMPLEMENTATION
```

_Storage slot with the address of the current implementation. `keccak256('eip1967.proxy.implementation') - 1`._

### PREFIX_COMMAND_EXECUTED

```solidity
bytes32 PREFIX_COMMAND_EXECUTED
```

### PREFIX_TOKEN_ADDRESS

```solidity
bytes32 PREFIX_TOKEN_ADDRESS
```

### PREFIX_TOKEN_TYPE

```solidity
bytes32 PREFIX_TOKEN_TYPE
```

### PREFIX_CONTRACT_CALL_APPROVED

```solidity
bytes32 PREFIX_CONTRACT_CALL_APPROVED
```

### PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT

```solidity
bytes32 PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT
```

### PREFIX_TOKEN_MINT_LIMIT

```solidity
bytes32 PREFIX_TOKEN_MINT_LIMIT
```

### PREFIX_TOKEN_MINT_AMOUNT

```solidity
bytes32 PREFIX_TOKEN_MINT_AMOUNT
```

### SELECTOR_BURN_TOKEN

```solidity
bytes32 SELECTOR_BURN_TOKEN
```

### SELECTOR_DEPLOY_TOKEN

```solidity
bytes32 SELECTOR_DEPLOY_TOKEN
```

### SELECTOR_MINT_TOKEN

```solidity
bytes32 SELECTOR_MINT_TOKEN
```

### SELECTOR_APPROVE_CONTRACT_CALL

```solidity
bytes32 SELECTOR_APPROVE_CONTRACT_CALL
```

### SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT

```solidity
bytes32 SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT
```

### SELECTOR_TRANSFER_OPERATORSHIP

```solidity
bytes32 SELECTOR_TRANSFER_OPERATORSHIP
```

### TOKEN_DEPLOYER_IMPLEMENTATION

```solidity
address TOKEN_DEPLOYER_IMPLEMENTATION
```

### constructor

```solidity
constructor(address tokenDeployerImplementation_) public
```

### sendToken

```solidity
function sendToken(string destinationChain, string destinationAddress, string symbol, uint256 amount) external
```

### callContract

```solidity
function callContract(string destinationChain, string destinationContractAddress, bytes payload) external
```

### callContractWithToken

```solidity
function callContractWithToken(string destinationChain, string destinationContractAddress, bytes payload, string symbol, uint256 amount) external
```

### isContractCallApproved

```solidity
function isContractCallApproved(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash) external view returns (bool)
```

### isContractCallAndMintApproved

```solidity
function isContractCallAndMintApproved(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash, string symbol, uint256 amount) external view returns (bool)
```

### validateContractCall

```solidity
function validateContractCall(bytes32 commandId, string sourceChain, string sourceAddress, bytes32 payloadHash) external returns (bool valid)
```

### validateContractCallAndMint

```solidity
function validateContractCallAndMint(bytes32 commandId, string sourceChain, string sourceAddress, bytes32 payloadHash, string symbol, uint256 amount) external returns (bool valid)
```

### authModule

```solidity
function authModule() public pure returns (address)
```

### tokenDeployer

```solidity
function tokenDeployer() public view returns (address)
```

### tokenMintLimit

```solidity
function tokenMintLimit(string symbol) public view returns (uint256)
```

### tokenMintAmount

```solidity
function tokenMintAmount(string symbol) public view returns (uint256)
```

### allTokensFrozen

```solidity
function allTokensFrozen() external pure returns (bool)
```

_This function is kept around to keep things working for internal
tokens that were deployed before the token freeze functionality was removed_

### implementation

```solidity
function implementation() public view returns (address)
```

### tokenAddresses

```solidity
function tokenAddresses(string symbol) public view returns (address)
```

### tokenFrozen

```solidity
function tokenFrozen(string) external pure returns (bool)
```

_This function is kept around to keep things working for internal
tokens that were deployed before the token freeze functionality was removed_

### isCommandExecuted

```solidity
function isCommandExecuted(bytes32 commandId) public view returns (bool)
```

### adminEpoch

```solidity
function adminEpoch() external pure returns (uint256)
```

_Returns the current `adminEpoch`._

### adminThreshold

```solidity
function adminThreshold(uint256) external pure returns (uint256)
```

_Returns the admin threshold for a given `adminEpoch`._

### admins

```solidity
function admins(uint256) external pure returns (address[] results)
```

_Returns the array of admins within a given `adminEpoch`._

### setTokenMintLimits

```solidity
function setTokenMintLimits(string[] symbols, uint256[] limits) external
```

### upgrade

```solidity
function upgrade(address newImplementation, bytes32 newImplementationCodeHash, bytes setupParams) external
```

### setup

```solidity
function setup(bytes) external view
```

_Not publicly accessible as overshadowed in the proxy_

### execute

```solidity
function execute(bytes input) external
```

### deployToken

```solidity
function deployToken(bytes params, bytes32) external
```

### mintToken

```solidity
function mintToken(bytes params, bytes32) external
```

### burnToken

```solidity
function burnToken(bytes params, bytes32) external
```

### approveContractCall

```solidity
function approveContractCall(bytes params, bytes32 commandId) external
```

### approveContractCallWithMint

```solidity
function approveContractCallWithMint(bytes params, bytes32 commandId) external
```

### transferOperatorship

```solidity
function transferOperatorship(bytes newOperatorsData, bytes32) external
```

### _mintToken

```solidity
function _mintToken(string symbol, address account, uint256 amount) internal
```

### _burnTokenFrom

```solidity
function _burnTokenFrom(address sender, string symbol, uint256 amount) internal
```

### _getTokenMintLimitKey

```solidity
function _getTokenMintLimitKey(string symbol) internal pure returns (bytes32)
```

### _getTokenMintAmountKey

```solidity
function _getTokenMintAmountKey(string symbol, uint256 day) internal pure returns (bytes32)
```

### _getTokenTypeKey

```solidity
function _getTokenTypeKey(string symbol) internal pure returns (bytes32)
```

### _getTokenAddressKey

```solidity
function _getTokenAddressKey(string symbol) internal pure returns (bytes32)
```

### _getIsCommandExecutedKey

```solidity
function _getIsCommandExecutedKey(bytes32 commandId) internal pure returns (bytes32)
```

### _getIsContractCallApprovedKey

```solidity
function _getIsContractCallApprovedKey(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash) internal pure returns (bytes32)
```

### _getIsContractCallApprovedWithMintKey

```solidity
function _getIsContractCallApprovedWithMintKey(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash, string symbol, uint256 amount) internal pure returns (bytes32)
```

### _getCreate2Address

```solidity
function _getCreate2Address(bytes32 salt, bytes32 codeHash) internal view returns (address)
```

### _getTokenType

```solidity
function _getTokenType(string symbol) internal view returns (enum MockAxelarGateway.TokenType)
```

### _setTokenMintLimit

```solidity
function _setTokenMintLimit(string symbol, uint256 limit) internal
```

### _setTokenMintAmount

```solidity
function _setTokenMintAmount(string symbol, uint256 amount) internal
```

### _setTokenType

```solidity
function _setTokenType(string symbol, enum MockAxelarGateway.TokenType tokenType) internal
```

### _setTokenAddress

```solidity
function _setTokenAddress(string symbol, address tokenAddress) internal
```

### _setCommandExecuted

```solidity
function _setCommandExecuted(bytes32 commandId, bool executed) internal
```

### _setContractCallApproved

```solidity
function _setContractCallApproved(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash) internal
```

### _setContractCallApprovedWithMint

```solidity
function _setContractCallApprovedWithMint(bytes32 commandId, string sourceChain, string sourceAddress, address contractAddress, bytes32 payloadHash, string symbol, uint256 amount) internal
```

### _setImplementation

```solidity
function _setImplementation(address newImplementation) internal
```

## StandardizedTokenDeployer

### deployer

```solidity
contract Create3Deployer deployer
```

### implementationAddress

```solidity
address implementationAddress
```

### constructor

```solidity
constructor(address deployer_, address implementationAddress_) public
```

### deployStandardizedToken

```solidity
function deployStandardizedToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) external payable
```

## TokenManagerDeployer

### deployer

```solidity
contract Create3Deployer deployer
```

### constructor

```solidity
constructor(address deployer_) public
```

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable
```

