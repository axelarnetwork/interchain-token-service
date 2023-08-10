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

### implementationLiquidityPool

```solidity
address implementationLiquidityPool
```

### gasService

```solidity
contract IAxelarGasService gasService
```

### remoteAddressValidator

```solidity
contract IRemoteAddressValidator remoteAddressValidator
```

### tokenManagerDeployer

```solidity
address tokenManagerDeployer
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### standardizedTokenDeployer

```solidity
address standardizedTokenDeployer
```

Returns the address of the standardized token deployer contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

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

### constructor

```solidity
constructor(address tokenManagerDeployer_, address standardizedTokenDeployer_, address gateway_, address gasService_, address remoteAddressValidator_, address[] tokenManagerImplementations, string chainName_) public
```

_All of the variables passed here are stored as immutable variables._

#### Parameters

| Name                        | Type      | Description                                                                                                         |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| tokenManagerDeployer\_      | address   | the address of the TokenManagerDeployer.                                                                            |
| standardizedTokenDeployer\_ | address   | the address of the StandardizedTokenDeployer.                                                                       |
| gateway\_                   | address   | the address of the AxelarGateway.                                                                                   |
| gasService\_                | address   | the address of the AxelarGasService.                                                                                |
| remoteAddressValidator\_    | address   | the address of the RemoteAddressValidator.                                                                          |
| tokenManagerImplementations | address[] | this need to have exactly 3 implementations in the following order: Lock/Unlock, mint/burn and then liquidity pool. |
| chainName\_                 | string    | the name of the current chain.                                                                                      |

### onlyRemoteService

```solidity
modifier onlyRemoteService(string sourceChain, string sourceAddress)
```

This modifier is used to ensure that only a remote InterchainTokenService can \_execute this one.

#### Parameters

| Name          | Type   | Description                          |
| ------------- | ------ | ------------------------------------ |
| sourceChain   | string | the source of the contract call.     |
| sourceAddress | string | the address that the call came from. |

### onlyTokenManager

```solidity
modifier onlyTokenManager(bytes32 tokenId)
```

This modifier is used to ensure certain functions can only be called by TokenManagers.

#### Parameters

| Name    | Type    | Description                                                   |
| ------- | ------- | ------------------------------------------------------------- |
| tokenId | bytes32 | the `tokenId` of the TokenManager trying to perform the call. |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### getChainName

```solidity
function getChainName() public view returns (string name)
```

Getter for the chain name.

#### Return Values

| Name | Type   | Description           |
| ---- | ------ | --------------------- |
| name | string | the name of the chain |

### getTokenManagerAddress

```solidity
function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress)
```

Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.

#### Parameters

| Name    | Type    | Description  |
| ------- | ------- | ------------ |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name                | Type    | Description                             |
| ------------------- | ------- | --------------------------------------- |
| tokenManagerAddress | address | deployment address of the TokenManager. |

### getValidTokenManagerAddress

```solidity
function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress)
```

Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.

#### Parameters

| Name    | Type    | Description  |
| ------- | ------- | ------------ |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name                | Type    | Description                             |
| ------------------- | ------- | --------------------------------------- |
| tokenManagerAddress | address | deployment address of the TokenManager. |

### getTokenAddress

```solidity
function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the token that an existing tokenManager points to.

#### Parameters

| Name    | Type    | Description  |
| ------- | ------- | ------------ |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| tokenAddress | address | the address of the token. |

### getStandardizedTokenAddress

```solidity
function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress)
```

Returns the address of the standardized token that would be deployed with a given tokenId.
The token does not need to exist.

#### Parameters

| Name    | Type    | Description  |
| ------- | ------- | ------------ |
| tokenId | bytes32 | the tokenId. |

#### Return Values

| Name         | Type    | Description                            |
| ------------ | ------- | -------------------------------------- |
| tokenAddress | address | the address of the standardized token. |

### getCanonicalTokenId

```solidity
function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a canonical link for a given token.
This will depend on what chain it is called from, unlike custom tokenIds.

#### Parameters

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| tokenAddress | address | the address of the token. |

#### Return Values

| Name    | Type    | Description                                                                          |
| ------- | ------- | ------------------------------------------------------------------------------------ |
| tokenId | bytes32 | the tokenId that the canonical TokenManager would get (or has gotten) for the token. |

### getCustomTokenId

```solidity
function getCustomTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId)
```

Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
This will not depend on what chain it is called from, unlike canonical tokenIds.

#### Parameters

| Name   | Type    | Description                                         |
| ------ | ------- | --------------------------------------------------- |
| sender | address | the address of the TokenManager deployer.           |
| salt   | bytes32 | the salt that the deployer uses for the deployment. |

#### Return Values

| Name    | Type    | Description                                                         |
| ------- | ------- | ------------------------------------------------------------------- |
| tokenId | bytes32 | the tokenId that the custom TokenManager would get (or has gotten). |

### getImplementation

```solidity
function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress)
```

Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
to figure out their implementations

#### Parameters

| Name             | Type    | Description                   |
| ---------------- | ------- | ----------------------------- |
| tokenManagerType | uint256 | the type of the TokenManager. |

#### Return Values

| Name                | Type    | Description                                    |
| ------------------- | ------- | ---------------------------------------------- |
| tokenManagerAddress | address | the address of the TokenManagerImplementation. |

### getParamsLockUnlock

```solidity
function getParamsLockUnlock(bytes operator, address tokenAddress) public pure returns (bytes params)
```

Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.

#### Parameters

| Name         | Type    | Description                       |
| ------------ | ------- | --------------------------------- |
| operator     | bytes   | the operator of the TokenManager. |
| tokenAddress | address | the token to be managed.          |

#### Return Values

| Name   | Type  | Description                                                           |
| ------ | ----- | --------------------------------------------------------------------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### getParamsMintBurn

```solidity
function getParamsMintBurn(bytes operator, address tokenAddress) public pure returns (bytes params)
```

Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.

#### Parameters

| Name         | Type    | Description                       |
| ------------ | ------- | --------------------------------- |
| operator     | bytes   | the operator of the TokenManager. |
| tokenAddress | address | the token to be managed.          |

#### Return Values

| Name   | Type  | Description                                                           |
| ------ | ----- | --------------------------------------------------------------------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### getParamsLiquidityPool

```solidity
function getParamsLiquidityPool(bytes operator, address tokenAddress, address liquidityPoolAddress) public pure returns (bytes params)
```

Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.

#### Parameters

| Name                 | Type    | Description                                                |
| -------------------- | ------- | ---------------------------------------------------------- |
| operator             | bytes   | the operator of the TokenManager.                          |
| tokenAddress         | address | the token to be managed.                                   |
| liquidityPoolAddress | address | the liquidity pool to be used to store the bridged tokens. |

#### Return Values

| Name   | Type  | Description                                                           |
| ------ | ----- | --------------------------------------------------------------------- |
| params | bytes | the resulting params to be passed to custom TokenManager deployments. |

### getFlowLimit

```solidity
function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit)
```

Getter function for the flow limit of an existing token manager with a give token ID.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name      | Type    | Description     |
| --------- | ------- | --------------- |
| flowLimit | uint256 | the flow limit. |

### getFlowOutAmount

```solidity
function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount)
```

Getter function for the flow out amount of an existing token manager with a give token ID.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name          | Type    | Description          |
| ------------- | ------- | -------------------- |
| flowOutAmount | uint256 | the flow out amount. |

### getFlowInAmount

```solidity
function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount)
```

Getter function for the flow in amount of an existing token manager with a give token ID.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | the token ID of the TokenManager. |

#### Return Values

| Name         | Type    | Description         |
| ------------ | ------- | ------------------- |
| flowInAmount | uint256 | the flow in amount. |

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Used to register canonical tokens. Caller does not matter.

#### Parameters

| Name         | Type    | Description              |
| ------------ | ------- | ------------------------ |
| tokenAddress | address | the token to be bridged. |

#### Return Values

| Name    | Type    | Description                                         |
| ------- | ------- | --------------------------------------------------- |
| tokenId | bytes32 | the tokenId that was used for this canonical token. |

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(bytes32 tokenId, string destinationChain, uint256 gasValue) public payable
```

Used to deploy remote TokenManagers and standardized tokens for a canonical token. This needs to be
called from the chain that registered the canonical token, and anyone can call it.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name             | Type    | Description                                                                                                                                   |
| ---------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| tokenId          | bytes32 | the tokenId of the canonical token.                                                                                                           |
| destinationChain | string  | the name of the chain to deploy the TokenManager and standardized token to.                                                                   |
| gasValue         | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### deployCustomTokenManager

```solidity
function deployCustomTokenManager(bytes32 salt, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) public payable returns (bytes32 tokenId)
```

Used to deploy custom TokenManagers with the specified salt. Different callers would result in different tokenIds.

#### Parameters

| Name             | Type                                    | Description                                                  |
| ---------------- | --------------------------------------- | ------------------------------------------------------------ |
| salt             | bytes32                                 | the salt to be used.                                         |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | the type of TokenManager to be deployed.                     |
| params           | bytes                                   | the params that will be used to initialize the TokenManager. |

### deployRemoteCustomTokenManager

```solidity
function deployRemoteCustomTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Used to deploy remote custom TokenManagers.

_`gasValue` exists because this function can be part of a multicall involving multiple functions
that could make remote contract calls._

#### Parameters

| Name             | Type                                    | Description                                                                                                                                   |
| ---------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| salt             | bytes32                                 | the salt to be used.                                                                                                                          |
| destinationChain | string                                  | the name of the chain to deploy the TokenManager and standardized token to.                                                                   |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | the type of TokenManager to be deployed.                                                                                                      |
| params           | bytes                                   | the params that will be used to initialize the TokenManager.                                                                                  |
| gasValue         | uint256                                 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### deployAndRegisterStandardizedToken

```solidity
function deployAndRegisterStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor) external payable
```

Used to deploy a standardized token alongside a TokenManager. If the `distributor` is the address of the TokenManager (which
can be calculated ahead of time) then a mint/burn TokenManager is used. Otherwise a lock/unlock TokenManager is used.

#### Parameters

| Name        | Type    | Description                                                        |
| ----------- | ------- | ------------------------------------------------------------------ |
| salt        | bytes32 | the salt to be used.                                               |
| name        | string  | the name of the token to be deployed.                              |
| symbol      | string  | the symbol of the token to be deployed.                            |
| decimals    | uint8   | the decimals of the token to be deployed.                          |
| mintAmount  | uint256 | the amount of token to be mint during deployment to msg.sender.    |
| distributor | address | the address that will be able to mint and burn the deployed token. |

### deployAndRegisterRemoteStandardizedToken

```solidity
function deployAndRegisterRemoteStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue) external payable
```

Used to deploy a standardized token alongside a TokenManager in another chain. If the `distributor` is empty
bytes then a mint/burn TokenManager is used. Otherwise a lock/unlock TokenManager is used.

_`gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls._

#### Parameters

| Name             | Type    | Description                                                                                                                                   |
| ---------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| salt             | bytes32 | the salt to be used.                                                                                                                          |
| name             | string  | the name of the token to be deployed.                                                                                                         |
| symbol           | string  | the symbol of the token to be deployed.                                                                                                       |
| decimals         | uint8   | the decimals of the token to be deployed.                                                                                                     |
| distributor      | bytes   | the address that will be able to mint and burn the deployed token.                                                                            |
| operator         | bytes   |                                                                                                                                               |
| destinationChain | string  | the name of the destination chain to deploy to.                                                                                               |
| gasValue         | uint256 | the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call |

### expressReceiveToken

```solidity
function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
sendToken that matches the parameters passed here.

#### Parameters

| Name               | Type    | Description                               |
| ------------------ | ------- | ----------------------------------------- |
| tokenId            | bytes32 | the tokenId of the TokenManager used.     |
| destinationAddress | address | the destinationAddress for the sendToken. |
| amount             | uint256 | the amount of token to give.              |
| commandId          | bytes32 | the sendHash detected at the sourceChain. |

### expressReceiveTokenWithData

```solidity
function expressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) external
```

Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have
detected an outgoing sendToken that matches the parameters passed here.

#### Parameters

| Name               | Type    | Description                                                                         |
| ------------------ | ------- | ----------------------------------------------------------------------------------- |
| tokenId            | bytes32 | the tokenId of the TokenManager used.                                               |
| sourceChain        | string  | the name of the chain where the call came from.                                     |
| sourceAddress      | bytes   | the caller of callContractWithInterchainToken.                                      |
| destinationAddress | address | the destinationAddress for the sendToken.                                           |
| amount             | uint256 | the amount of token to give.                                                        |
| data               | bytes   | the data to be passed to destinationAddress after giving them the tokens specified. |
| commandId          | bytes32 | the sendHash detected at the sourceChain.                                           |

### transmitSendToken

```solidity
function transmitSendToken(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Transmit a sendTokenWithData for the given tokenId. Only callable by a token manager.

#### Parameters

| Name               | Type    | Description                                                                                   |
| ------------------ | ------- | --------------------------------------------------------------------------------------------- |
| tokenId            | bytes32 | the tokenId of the TokenManager (which must be the msg.sender).                               |
| sourceAddress      | address | the address where the token is coming from, which will also be used for reimbursement of gas. |
| destinationChain   | string  | the name of the chain to send tokens to.                                                      |
| destinationAddress | bytes   | the destinationAddress for the sendToken.                                                     |
| amount             | uint256 | the amount of token to give.                                                                  |
| metadata           | bytes   | the data to be passed to the destination.                                                     |

### setFlowLimit

```solidity
function setFlowLimit(bytes32[] tokenIds, uint256[] flowLimits) external
```

Used to set a flow limit for a token manager that has the service as its operator.

#### Parameters

| Name       | Type      | Description                                                              |
| ---------- | --------- | ------------------------------------------------------------------------ |
| tokenIds   | bytes32[] | an array of the token Ids of the tokenManagers to set the flow limit of. |
| flowLimits | uint256[] | the flowLimits to set                                                    |

### setPaused

```solidity
function setPaused(bool paused) external
```

Used to pause the entire service.

#### Parameters

| Name   | Type | Description                  |
| ------ | ---- | ---------------------------- |
| paused | bool | what value to set paused to. |

### \_setup

```solidity
function _setup(bytes params) internal
```

### \_sanitizeTokenManagerImplementation

```solidity
function _sanitizeTokenManagerImplementation(address[] implementations, enum ITokenManagerType.TokenManagerType tokenManagerType) internal pure returns (address implementation)
```

### \_execute

```solidity
function _execute(string sourceChain, string sourceAddress, bytes payload) internal
```

Executes operations based on the payload and selector.

#### Parameters

| Name          | Type   | Description                                       |
| ------------- | ------ | ------------------------------------------------- |
| sourceChain   | string | The chain where the transaction originates from   |
| sourceAddress | string | The address where the transaction originates from |
| payload       | bytes  | The encoded data payload for the transaction      |

### \_processSendTokenPayload

```solidity
function _processSendTokenPayload(string sourceChain, bytes payload) internal
```

Processes the payload data for a send token call

#### Parameters

| Name        | Type   | Description                                     |
| ----------- | ------ | ----------------------------------------------- |
| sourceChain | string | The chain where the transaction originates from |
| payload     | bytes  | The encoded data payload to be processed        |

### \_processSendTokenWithDataPayload

```solidity
function _processSendTokenWithDataPayload(string sourceChain, bytes payload) internal
```

Processes a send token with data payload.

#### Parameters

| Name        | Type   | Description                                     |
| ----------- | ------ | ----------------------------------------------- |
| sourceChain | string | The chain where the transaction originates from |
| payload     | bytes  | The encoded data payload to be processed        |

### \_processDeployTokenManagerPayload

```solidity
function _processDeployTokenManagerPayload(bytes payload) internal
```

Processes a deploy token manager payload.

#### Parameters

| Name    | Type  | Description                              |
| ------- | ----- | ---------------------------------------- |
| payload | bytes | The encoded data payload to be processed |

### \_processDeployStandardizedTokenAndManagerPayload

```solidity
function _processDeployStandardizedTokenAndManagerPayload(bytes payload) internal
```

Process a deploy standardized token and manager payload.

#### Parameters

| Name    | Type  | Description                              |
| ------- | ----- | ---------------------------------------- |
| payload | bytes | The encoded data payload to be processed |

### \_callContract

```solidity
function _callContract(string destinationChain, bytes payload, uint256 gasValue, address refundTo) internal
```

Calls a contract on a specific destination chain with the given payload

#### Parameters

| Name             | Type    | Description                                                   |
| ---------------- | ------- | ------------------------------------------------------------- |
| destinationChain | string  | The target chain where the contract will be called            |
| payload          | bytes   | The data payload for the transaction                          |
| gasValue         | uint256 | The amount of gas to be paid for the transaction              |
| refundTo         | address | The address where the unused gas amount should be refunded to |

### \_validateToken

```solidity
function _validateToken(address tokenAddress) internal returns (string name, string symbol, uint8 decimals)
```

### \_deployRemoteTokenManager

```solidity
function _deployRemoteTokenManager(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager on a destination chain.

#### Parameters

| Name             | Type                                    | Description                                            |
| ---------------- | --------------------------------------- | ------------------------------------------------------ |
| tokenId          | bytes32                                 | The ID of the token                                    |
| destinationChain | string                                  | The chain where the token manager will be deployed     |
| gasValue         | uint256                                 | The amount of gas to be paid for the transaction       |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager to be deployed               |
| params           | bytes                                   | Additional parameters for the token manager deployment |

### \_deployRemoteStandardizedToken

```solidity
function _deployRemoteStandardizedToken(bytes32 tokenId, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue) internal
```

Deploys a standardized token on a destination chain.

#### Parameters

| Name             | Type    | Description                                            |
| ---------------- | ------- | ------------------------------------------------------ |
| tokenId          | bytes32 | The ID of the token                                    |
| name             | string  | The name of the token                                  |
| symbol           | string  | The symbol of the token                                |
| decimals         | uint8   | The number of decimals of the token                    |
| distributor      | bytes   | The distributor address for the token                  |
| operator         | bytes   |                                                        |
| destinationChain | string  | The destination chain where the token will be deployed |
| gasValue         | uint256 | The amount of gas to be paid for the transaction       |

### \_deployTokenManager

```solidity
function _deployTokenManager(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) internal
```

Deploys a token manager

#### Parameters

| Name             | Type                                    | Description                                            |
| ---------------- | --------------------------------------- | ------------------------------------------------------ |
| tokenId          | bytes32                                 | The ID of the token                                    |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of the token manager to be deployed           |
| params           | bytes                                   | Additional parameters for the token manager deployment |

### \_getStandardizedTokenSalt

```solidity
function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt)
```

Compute the salt for a standardized token deployment.

#### Parameters

| Name    | Type    | Description         |
| ------- | ------- | ------------------- |
| tokenId | bytes32 | The ID of the token |

#### Return Values

| Name | Type    | Description                                |
| ---- | ------- | ------------------------------------------ |
| salt | bytes32 | The computed salt for the token deployment |

### \_deployStandardizedToken

```solidity
function _deployStandardizedToken(bytes32 tokenId, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) internal
```

Deploys a standardized token.

#### Parameters

| Name        | Type    | Description                                                      |
| ----------- | ------- | ---------------------------------------------------------------- |
| tokenId     | bytes32 | The ID of the token                                              |
| distributor | address | The distributor address for the token                            |
| name        | string  | The name of the token                                            |
| symbol      | string  | The symbol of the token                                          |
| decimals    | uint8   | The number of decimals of the token                              |
| mintAmount  | uint256 | The amount of tokens to be minted upon deployment                |
| mintTo      | address | The address where the minted tokens will be sent upon deployment |

### \_decodeMetadata

```solidity
function _decodeMetadata(bytes metadata) internal pure returns (uint32 version, bytes data)
```

### \_expressExecuteWithInterchainTokenToken

```solidity
function _expressExecuteWithInterchainTokenToken(bytes32 tokenId, address destinationAddress, string sourceChain, bytes sourceAddress, bytes data, uint256 amount) internal
```

## IERC20Named

_Interface of the ERC20 standard as defined in the EIP._

### name

```solidity
function name() external returns (string)
```

Getter for the name of the token

### symbol

```solidity
function symbol() external returns (string)
```

Getter for the symbol of the token

### decimals

```solidity
function decimals() external returns (uint8)
```

Getter for the decimals of the token

## IExpressCallHandler

### AlreadyExpressCalled

```solidity
error AlreadyExpressCalled()
```

### SameDestinationAsCaller

```solidity
error SameDestinationAsCaller()
```

### ExpressReceive

```solidity
event ExpressReceive(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash, address expressCaller)
```

### ExpressExecutionFulfilled

```solidity
event ExpressExecutionFulfilled(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash, address expressCaller)
```

### ExpressReceiveWithData

```solidity
event ExpressReceiveWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash, address expressCaller)
```

### ExpressExecutionWithDataFulfilled

```solidity
event ExpressExecutionWithDataFulfilled(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 sendHash, address expressCaller)
```

### getExpressReceiveToken

```solidity
function getExpressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external view returns (address expressCaller)
```

Gets the address of the express caller for a specific token transfer

#### Parameters

| Name               | Type    | Description                             |
| ------------------ | ------- | --------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent          |
| destinationAddress | address | The address of the recipient            |
| amount             | uint256 | The amount of tokens to be sent         |
| commandId          | bytes32 | The unique hash for this token transfer |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

### getExpressReceiveTokenWithData

```solidity
function getExpressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) external view returns (address expressCaller)
```

Gets the address of the express caller for a specific token transfer with data

#### Parameters

| Name               | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent                           |
| sourceChain        | string  | The chain from which the token will be sent              |
| sourceAddress      | bytes   | The originating address of the token on the source chain |
| destinationAddress | address | The address of the recipient on the destination chain    |
| amount             | uint256 | The amount of tokens to be sent                          |
| data               | bytes   | The data associated with the token transfer              |
| commandId          | bytes32 | The unique hash for this token transfer                  |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

## IFlowLimit

### FlowLimitExceeded

```solidity
error FlowLimitExceeded()
```

### FlowLimitSet

```solidity
event FlowLimitSet(uint256 flowLimit)
```

### getFlowLimit

```solidity
function getFlowLimit() external view returns (uint256 flowLimit)
```

Returns the current flow limit

#### Return Values

| Name      | Type    | Description                  |
| --------- | ------- | ---------------------------- |
| flowLimit | uint256 | The current flow limit value |

### getFlowOutAmount

```solidity
function getFlowOutAmount() external view returns (uint256 flowOutAmount)
```

Returns the current flow out amount

#### Return Values

| Name          | Type    | Description                 |
| ------------- | ------- | --------------------------- |
| flowOutAmount | uint256 | The current flow out amount |

### getFlowInAmount

```solidity
function getFlowInAmount() external view returns (uint256 flowInAmount)
```

Returns the current flow in amount

#### Return Values

| Name         | Type    | Description                |
| ------------ | ------- | -------------------------- |
| flowInAmount | uint256 | The current flow in amount |

## IImplementation

### NotProxy

```solidity
error NotProxy()
```

## IInterchainTokenExecutable

Implement this to accept calls from the InterchainTokenService.

### executeWithInterchainToken

```solidity
function executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

This will be called after the tokens arrive to this contract

_You are revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name          | Type    | Description                                                                                              |
| ------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| sourceChain   | string  | the name of the source chain                                                                             |
| sourceAddress | bytes   | the address that sent the contract call                                                                  |
| data          | bytes   | the data to be proccessed                                                                                |
| tokenId       | bytes32 | the tokenId of the token manager managing the token. You can access it's address by querying the service |
| amount        | uint256 | the amount of token that was sent                                                                        |

## IInterchainTokenExpressExecutable

Implement this to accept express calls from the InterchainTokenService.

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

This will be called after the tokens arrive to this contract

_You are revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name          | Type    | Description                                                                                              |
| ------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| sourceChain   | string  | the name of the source chain                                                                             |
| sourceAddress | bytes   | the address that sent the contract call                                                                  |
| data          | bytes   | the data to be proccessed                                                                                |
| tokenId       | bytes32 | the tokenId of the token manager managing the token. You can access it's address by querying the service |
| amount        | uint256 | the amount of token that was sent                                                                        |

## IInterchainTokenService

### ZeroAddress

```solidity
error ZeroAddress()
```

### LengthMismatch

```solidity
error LengthMismatch()
```

### InvalidTokenManagerImplementation

```solidity
error InvalidTokenManagerImplementation()
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

### DoesNotAcceptExpressExecute

```solidity
error DoesNotAcceptExpressExecute(address contractAddress)
```

### SelectorUnknown

```solidity
error SelectorUnknown()
```

### InvalidMetadataVersion

```solidity
error InvalidMetadataVersion(uint32 version)
```

### AlreadyExecuted

```solidity
error AlreadyExecuted(bytes32 commandId)
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
event TokenReceived(bytes32 tokenId, string sourceChain, address destinationAddress, uint256 amount)
```

### TokenReceivedWithData

```solidity
event TokenReceivedWithData(bytes32 tokenId, string sourceChain, address destinationAddress, uint256 amount, bytes sourceAddress, bytes data)
```

### RemoteTokenManagerDeploymentInitialized

```solidity
event RemoteTokenManagerDeploymentInitialized(bytes32 tokenId, string destinationChain, uint256 gasValue, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### RemoteStandardizedTokenAndManagerDeploymentInitialized

```solidity
event RemoteStandardizedTokenAndManagerDeploymentInitialized(bytes32 tokenId, string tokenName, string tokenSymbol, uint8 tokenDecimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue)
```

### TokenManagerDeployed

```solidity
event TokenManagerDeployed(bytes32 tokenId, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params)
```

### StandardizedTokenDeployed

```solidity
event StandardizedTokenDeployed(bytes32 tokenId, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo)
```

### CustomTokenIdClaimed

```solidity
event CustomTokenIdClaimed(bytes32 tokenId, address deployer, bytes32 salt)
```

### tokenManagerDeployer

```solidity
function tokenManagerDeployer() external view returns (address tokenManagerDeployerAddress)
```

Returns the address of the token manager deployer contract.

#### Return Values

| Name                        | Type    | Description                                         |
| --------------------------- | ------- | --------------------------------------------------- |
| tokenManagerDeployerAddress | address | The address of the token manager deployer contract. |

### standardizedTokenDeployer

```solidity
function standardizedTokenDeployer() external view returns (address standardizedTokenDeployerAddress)
```

Returns the address of the standardized token deployer contract.

#### Return Values

| Name                             | Type    | Description                                              |
| -------------------------------- | ------- | -------------------------------------------------------- |
| standardizedTokenDeployerAddress | address | The address of the standardized token deployer contract. |

### getChainName

```solidity
function getChainName() external view returns (string name)
```

Returns the name of the current chain.

#### Return Values

| Name | Type   | Description                    |
| ---- | ------ | ------------------------------ |
| name | string | The name of the current chain. |

### getTokenManagerAddress

```solidity
function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress)
```

Returns the address of the token manager associated with the given tokenId.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name                | Type    | Description                       |
| ------------------- | ------- | --------------------------------- |
| tokenManagerAddress | address | The address of the token manager. |

### getValidTokenManagerAddress

```solidity
function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress)
```

Returns the address of the valid token manager associated with the given tokenId.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name                | Type    | Description                             |
| ------------------- | ------- | --------------------------------------- |
| tokenManagerAddress | address | The address of the valid token manager. |

### getTokenAddress

```solidity
function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the token associated with the given tokenId.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| tokenId | bytes32 | The tokenId of the token manager. |

#### Return Values

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| tokenAddress | address | The address of the token. |

### getStandardizedTokenAddress

```solidity
function getStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress)
```

Returns the address of the standardized token associated with the given tokenId.

#### Parameters

| Name    | Type    | Description                            |
| ------- | ------- | -------------------------------------- |
| tokenId | bytes32 | The tokenId of the standardized token. |

#### Return Values

| Name         | Type    | Description                            |
| ------------ | ------- | -------------------------------------- |
| tokenAddress | address | The address of the standardized token. |

### getCanonicalTokenId

```solidity
function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId)
```

Returns the canonical tokenId associated with the given tokenAddress.

#### Parameters

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| tokenId | bytes32 | The canonical tokenId associated with the tokenAddress. |

### getCustomTokenId

```solidity
function getCustomTokenId(address operator, bytes32 salt) external view returns (bytes32 tokenId)
```

Returns the custom tokenId associated with the given operator and salt.

#### Parameters

| Name     | Type    | Description                             |
| -------- | ------- | --------------------------------------- |
| operator | address | The operator address.                   |
| salt     | bytes32 | The salt used for token id calculation. |

#### Return Values

| Name    | Type    | Description                                               |
| ------- | ------- | --------------------------------------------------------- |
| tokenId | bytes32 | The custom tokenId associated with the operator and salt. |

### getParamsLockUnlock

```solidity
function getParamsLockUnlock(bytes operator, address tokenAddress) external pure returns (bytes params)
```

Returns the parameters for the lock/unlock operation.

#### Parameters

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| operator     | bytes   | The operator address.     |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name   | Type  | Description                                   |
| ------ | ----- | --------------------------------------------- |
| params | bytes | The parameters for the lock/unlock operation. |

### getParamsMintBurn

```solidity
function getParamsMintBurn(bytes operator, address tokenAddress) external pure returns (bytes params)
```

Returns the parameters for the mint/burn operation.

#### Parameters

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| operator     | bytes   | The operator address.     |
| tokenAddress | address | The address of the token. |

#### Return Values

| Name   | Type  | Description                                 |
| ------ | ----- | ------------------------------------------- |
| params | bytes | The parameters for the mint/burn operation. |

### getParamsLiquidityPool

```solidity
function getParamsLiquidityPool(bytes operator, address tokenAddress, address liquidityPoolAddress) external pure returns (bytes params)
```

Returns the parameters for the liquidity pool operation.

#### Parameters

| Name                 | Type    | Description                        |
| -------------------- | ------- | ---------------------------------- |
| operator             | bytes   | The operator address.              |
| tokenAddress         | address | The address of the token.          |
| liquidityPoolAddress | address | The address of the liquidity pool. |

#### Return Values

| Name   | Type  | Description                                      |
| ------ | ----- | ------------------------------------------------ |
| params | bytes | The parameters for the liquidity pool operation. |

### registerCanonicalToken

```solidity
function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId)
```

Registers a canonical token and returns its associated tokenId.

#### Parameters

| Name         | Type    | Description                         |
| ------------ | ------- | ----------------------------------- |
| tokenAddress | address | The address of the canonical token. |

#### Return Values

| Name    | Type    | Description                                                 |
| ------- | ------- | ----------------------------------------------------------- |
| tokenId | bytes32 | The tokenId associated with the registered canonical token. |

### deployRemoteCanonicalToken

```solidity
function deployRemoteCanonicalToken(bytes32 tokenId, string destinationChain, uint256 gasValue) external payable
```

Deploys a standardized canonical token on a remote chain.

#### Parameters

| Name             | Type    | Description                         |
| ---------------- | ------- | ----------------------------------- |
| tokenId          | bytes32 | The tokenId of the canonical token. |
| destinationChain | string  | The name of the destination chain.  |
| gasValue         | uint256 | The gas value for deployment.       |

### deployCustomTokenManager

```solidity
function deployCustomTokenManager(bytes32 salt, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params) external payable returns (bytes32 tokenId)
```

Deploys a custom token manager contract.

#### Parameters

| Name             | Type                                    | Description                                 |
| ---------------- | --------------------------------------- | ------------------------------------------- |
| salt             | bytes32                                 | The salt used for token manager deployment. |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager.                  |
| params           | bytes                                   | The deployment parameters.                  |

#### Return Values

| Name    | Type    | Description                                |
| ------- | ------- | ------------------------------------------ |
| tokenId | bytes32 | The tokenId of the deployed token manager. |

### deployRemoteCustomTokenManager

```solidity
function deployRemoteCustomTokenManager(bytes32 salt, string destinationChain, enum ITokenManagerType.TokenManagerType tokenManagerType, bytes params, uint256 gasValue) external payable returns (bytes32 tokenId)
```

Deploys a custom token manager contract on a remote chain.

#### Parameters

| Name             | Type                                    | Description                                 |
| ---------------- | --------------------------------------- | ------------------------------------------- |
| salt             | bytes32                                 | The salt used for token manager deployment. |
| destinationChain | string                                  | The name of the destination chain.          |
| tokenManagerType | enum ITokenManagerType.TokenManagerType | The type of token manager.                  |
| params           | bytes                                   | The deployment parameters.                  |
| gasValue         | uint256                                 | The gas value for deployment.               |

### deployAndRegisterStandardizedToken

```solidity
function deployAndRegisterStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, uint256 mintAmount, address distributor) external payable
```

Deploys a standardized token and registers it. The token manager type will be lock/unlock unless the distributor matches its address, in which case it will be a mint/burn one.

#### Parameters

| Name        | Type    | Description                                              |
| ----------- | ------- | -------------------------------------------------------- |
| salt        | bytes32 | The salt used for token deployment.                      |
| name        | string  | The name of the standardized token.                      |
| symbol      | string  | The symbol of the standardized token.                    |
| decimals    | uint8   | The number of decimals for the standardized token.       |
| mintAmount  | uint256 | The amount of tokens to mint to the deployer.            |
| distributor | address | The address of the distributor for mint/burn operations. |

### deployAndRegisterRemoteStandardizedToken

```solidity
function deployAndRegisterRemoteStandardizedToken(bytes32 salt, string name, string symbol, uint8 decimals, bytes distributor, bytes operator, string destinationChain, uint256 gasValue) external payable
```

Deploys and registers a standardized token on a remote chain.

#### Parameters

| Name             | Type    | Description                                         |
| ---------------- | ------- | --------------------------------------------------- |
| salt             | bytes32 | The salt used for token deployment.                 |
| name             | string  | The name of the standardized tokens.                |
| symbol           | string  | The symbol of the standardized tokens.              |
| decimals         | uint8   | The number of decimals for the standardized tokens. |
| distributor      | bytes   | The distributor data for mint/burn operations.      |
| operator         | bytes   | The operator data for standardized tokens.          |
| destinationChain | string  | The name of the destination chain.                  |
| gasValue         | uint256 | The gas value for deployment.                       |

### getImplementation

```solidity
function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress)
```

Returns the implementation address for a given token manager type.

#### Parameters

| Name             | Type    | Description                |
| ---------------- | ------- | -------------------------- |
| tokenManagerType | uint256 | The type of token manager. |

#### Return Values

| Name                | Type    | Description                                      |
| ------------------- | ------- | ------------------------------------------------ |
| tokenManagerAddress | address | The address of the token manager implementation. |

### transmitSendToken

```solidity
function transmitSendToken(bytes32 tokenId, address sourceAddress, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Initiates an interchain token transfer. Only callable by TokenManagers

#### Parameters

| Name               | Type    | Description                                       |
| ------------------ | ------- | ------------------------------------------------- |
| tokenId            | bytes32 | The tokenId of the token to be transmitted.       |
| sourceAddress      | address | The source address of the token.                  |
| destinationChain   | string  | The name of the destination chain.                |
| destinationAddress | bytes   | The destination address on the destination chain. |
| amount             | uint256 | The amount of tokens to transmit.                 |
| metadata           | bytes   | The metadata associated with the transmission.    |

### setFlowLimit

```solidity
function setFlowLimit(bytes32[] tokenIds, uint256[] flowLimits) external
```

Sets the flow limits for multiple tokens.

#### Parameters

| Name       | Type      | Description                                            |
| ---------- | --------- | ------------------------------------------------------ |
| tokenIds   | bytes32[] | An array of tokenIds.                                  |
| flowLimits | uint256[] | An array of flow limits corresponding to the tokenIds. |

### getFlowLimit

```solidity
function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit)
```

Returns the flow limit for a specific token.

#### Parameters

| Name    | Type    | Description               |
| ------- | ------- | ------------------------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name      | Type    | Description                   |
| --------- | ------- | ----------------------------- |
| flowLimit | uint256 | The flow limit for the token. |

### getFlowOutAmount

```solidity
function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount)
```

Returns the total amount of outgoing flow for a specific token.

#### Parameters

| Name    | Type    | Description               |
| ------- | ------- | ------------------------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name          | Type    | Description                                      |
| ------------- | ------- | ------------------------------------------------ |
| flowOutAmount | uint256 | The total amount of outgoing flow for the token. |

### getFlowInAmount

```solidity
function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount)
```

Returns the total amount of incoming flow for a specific token.

#### Parameters

| Name    | Type    | Description               |
| ------- | ------- | ------------------------- |
| tokenId | bytes32 | The tokenId of the token. |

#### Return Values

| Name         | Type    | Description                                      |
| ------------ | ------- | ------------------------------------------------ |
| flowInAmount | uint256 | The total amount of incoming flow for the token. |

### setPaused

```solidity
function setPaused(bool paused) external
```

Sets the paused state of the contract.

#### Parameters

| Name   | Type | Description                                                         |
| ------ | ---- | ------------------------------------------------------------------- |
| paused | bool | The boolean value indicating whether the contract is paused or not. |

### expressReceiveToken

```solidity
function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external
```

Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.

#### Parameters

| Name               | Type    | Description                                                 |
| ------------------ | ------- | ----------------------------------------------------------- |
| tokenId            | bytes32 | the tokenId of the TokenManager used.                       |
| destinationAddress | address | the destinationAddress for the sendToken.                   |
| amount             | uint256 | the amount of token to give.                                |
| commandId          | bytes32 | the commandId calculated from the event at the sourceChain. |

### expressReceiveTokenWithData

```solidity
function expressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) external
```

Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.

#### Parameters

| Name               | Type    | Description                                                                         |
| ------------------ | ------- | ----------------------------------------------------------------------------------- |
| tokenId            | bytes32 | the tokenId of the TokenManager used.                                               |
| sourceChain        | string  | the name of the chain where the call came from.                                     |
| sourceAddress      | bytes   | the caller of callContractWithInterchainToken.                                      |
| destinationAddress | address | the destinationAddress for the sendToken.                                           |
| amount             | uint256 | the amount of token to give.                                                        |
| data               | bytes   | the data to be passed to destinationAddress after giving them the tokens specified. |
| commandId          | bytes32 | the commandId calculated from the event at the sourceChain.                         |

## IMulticall

This contract is a multi-functional smart contract which allows for multiple
contract calls in a single transaction.

### multicall

```solidity
function multicall(bytes[] data) external payable returns (bytes[] results)
```

Performs multiple delegate calls and returns the results of all calls as an array

_This function requires that the contract has sufficient balance for the delegate calls.
If any of the calls fail, the function will revert with the failure message._

#### Parameters

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| data | bytes[] | An array of encoded function calls |

#### Return Values

| Name    | Type    | Description                                               |
| ------- | ------- | --------------------------------------------------------- |
| results | bytes[] | An bytes array with the return data of each function call |

## IOperatable

### NotOperator

```solidity
error NotOperator()
```

### OperatorshipTransferred

```solidity
event OperatorshipTransferred(address operator)
```

### operator

```solidity
function operator() external view returns (address operator_)
```

Get the address of the operator

#### Return Values

| Name       | Type    | Description     |
| ---------- | ------- | --------------- |
| operator\_ | address | of the operator |

### transferOperatorship

```solidity
function transferOperatorship(address operator_) external
```

Change the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name       | Type    | Description                     |
| ---------- | ------- | ------------------------------- |
| operator\_ | address | The address of the new operator |

## IPausable

This contract provides a mechanism to halt the execution of specific functions
if a pause condition is activated.

### PausedSet

```solidity
event PausedSet(bool paused)
```

### Paused

```solidity
error Paused()
```

### isPaused

```solidity
function isPaused() external view returns (bool)
```

Check if the contract is paused

#### Return Values

| Name | Type | Description                                                                      |
| ---- | ---- | -------------------------------------------------------------------------------- |
| [0]  | bool | paused A boolean representing the pause status. True if paused, false otherwise. |

## IRemoteAddressValidator

_Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract_

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

### TrustedAddressAdded

```solidity
event TrustedAddressAdded(string sourceChain, string sourceAddress)
```

### TrustedAddressRemoved

```solidity
event TrustedAddressRemoved(string sourceChain)
```

### GatewaySupportedChainAdded

```solidity
event GatewaySupportedChainAdded(string chain)
```

### GatewaySupportedChainRemoved

```solidity
event GatewaySupportedChainRemoved(string chain)
```

### validateSender

```solidity
function validateSender(string sourceChain, string sourceAddress) external view returns (bool)
```

_Validates that the sender is a valid interchain token service address_

#### Parameters

| Name          | Type   | Description                       |
| ------------- | ------ | --------------------------------- |
| sourceChain   | string | Source chain of the transaction   |
| sourceAddress | string | Source address of the transaction |

#### Return Values

| Name | Type | Description                                           |
| ---- | ---- | ----------------------------------------------------- |
| [0]  | bool | bool true if the sender is validated, false otherwise |

### addTrustedAddress

```solidity
function addTrustedAddress(string sourceChain, string sourceAddress) external
```

_Adds a trusted interchain token service address for the specified chain_

#### Parameters

| Name          | Type   | Description                                  |
| ------------- | ------ | -------------------------------------------- |
| sourceChain   | string | Chain name of the interchain token service   |
| sourceAddress | string | Interchain token service address to be added |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string sourceChain) external
```

_Removes a trusted interchain token service address_

#### Parameters

| Name        | Type   | Description                                              |
| ----------- | ------ | -------------------------------------------------------- |
| sourceChain | string | Chain name of the interchain token service to be removed |

### getRemoteAddress

```solidity
function getRemoteAddress(string chainName) external view returns (string remoteAddress)
```

_Fetches the interchain token service address for the specified chain_

#### Parameters

| Name      | Type   | Description       |
| --------- | ------ | ----------------- |
| chainName | string | Name of the chain |

#### Return Values

| Name          | Type   | Description                                              |
| ------------- | ------ | -------------------------------------------------------- |
| remoteAddress | string | Interchain token service address for the specified chain |

### supportedByGateway

```solidity
function supportedByGateway(string chainName) external view returns (bool)
```

Returns true if the gateway delivers token to this chain.

#### Parameters

| Name      | Type   | Description       |
| --------- | ------ | ----------------- |
| chainName | string | Name of the chain |

### addGatewaySupportedChains

```solidity
function addGatewaySupportedChains(string[] chainNames) external
```

_Adds chains that are supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                  |
| ---------- | -------- | -------------------------------------------- |
| chainNames | string[] | List of chain names to be added as supported |

### removeGatewaySupportedChains

```solidity
function removeGatewaySupportedChains(string[] chainNames) external
```

_Removes chains that are no longer supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                    |
| ---------- | -------- | ---------------------------------------------- |
| chainNames | string[] | List of chain names to be removed as supported |

## IStandardizedTokenDeployer

This contract is used to deploy new instances of the StandardizedTokenProxy contract.

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

Getter for the Create3Deployer.

### deployStandardizedToken

```solidity
function deployStandardizedToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) external payable
```

Deploys a new instance of the StandardizedTokenProxy contract

#### Parameters

| Name         | Type    | Description                        |
| ------------ | ------- | ---------------------------------- |
| salt         | bytes32 | The salt used by Create3Deployer   |
| tokenManager | address | Address of the token manager       |
| distributor  | address | Address of the distributor         |
| name         | string  | Name of the token                  |
| symbol       | string  | Symbol of the token                |
| decimals     | uint8   | Decimals of the token              |
| mintAmount   | uint256 | Amount of tokens to mint initially |
| mintTo       | address | Address to mint initial tokens to  |

## ITokenManager

This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.

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

A function that should return the address of the token.
Must be overridden in the inheriting contract.

#### Return Values

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| [0]  | address | address address of the token. |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### sendToken

```solidity
function sendToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.

#### Parameters

| Name               | Type    | Description                                   |
| ------------------ | ------- | --------------------------------------------- |
| destinationChain   | string  | the name of the chain to send tokens to.      |
| destinationAddress | bytes   | the address of the user to send tokens to.    |
| amount             | uint256 | the amount of tokens to take from msg.sender. |
| metadata           | bytes   |                                               |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable
```

Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.

#### Parameters

| Name               | Type    | Description                                   |
| ------------------ | ------- | --------------------------------------------- |
| destinationChain   | string  | the name of the chain to send tokens to.      |
| destinationAddress | bytes   | the address of the user to send tokens to.    |
| amount             | uint256 | the amount of tokens to take from msg.sender. |
| data               | bytes   | the data to pass to the destination contract. |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name               | Type    | Description                                                  |
| ------------------ | ------- | ------------------------------------------------------------ |
| sender             | address | the address of the user paying for the cross chain transfer. |
| destinationChain   | string  | the name of the chain to send tokens to.                     |
| destinationAddress | bytes   | the address of the user to send tokens to.                   |
| amount             | uint256 | the amount of tokens to take from msg.sender.                |
| metadata           | bytes   |                                                              |

### giveToken

```solidity
function giveToken(address destinationAddress, uint256 amount) external returns (uint256)
```

This function gives token to a specified address. Can only be called by the service.

#### Parameters

| Name               | Type    | Description                    |
| ------------------ | ------- | ------------------------------ |
| destinationAddress | address | the address to give tokens to. |
| amount             | uint256 | the amount of token to give.   |

#### Return Values

| Name | Type    | Description                                                                                                                         |
| ---- | ------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit) external
```

This function sets the flow limit for this TokenManager. Can only be called by the operator.

#### Parameters

| Name      | Type    | Description                                                                                        |
| --------- | ------- | -------------------------------------------------------------------------------------------------- |
| flowLimit | uint256 | the maximum difference between the tokens flowing in and/or out at any given interval of time (6h) |

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

### deployer

```solidity
function deployer() external view returns (contract Create3Deployer)
```

Getter for the Create3Deployer.

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable
```

Deploys a new instance of the TokenManagerProxy contract

#### Parameters

| Name               | Type    | Description                                                  |
| ------------------ | ------- | ------------------------------------------------------------ |
| tokenId            | bytes32 | The unique identifier for the token                          |
| implementationType | uint256 | Token manager implementation type                            |
| params             | bytes   | Additional parameters used in the setup of the token manager |

## ITokenManagerProxy

_This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
inherits from FixedProxy from the gmp sdk repo_

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

Returns implementation type of this token manager

### implementation

```solidity
function implementation() external view returns (address)
```

Returns the address of the current implementation.

#### Return Values

| Name | Type    | Description                                    |
| ---- | ------- | ---------------------------------------------- |
| [0]  | address | impl The address of the current implementation |

### tokenId

```solidity
function tokenId() external view returns (bytes32)
```

Returns token ID of the token manager.

## ITokenManagerType

A simple interface that defines all the token manager types

### TokenManagerType

```solidity
enum TokenManagerType {
    LOCK_UNLOCK,
    MINT_BURN,
    LIQUIDITY_POOL
}
```

## AddressBytesUtils

_This library provides utility functions to convert between `address` and `bytes`._

### InvalidBytesLength

```solidity
error InvalidBytesLength(bytes bytesAddress)
```

### toAddress

```solidity
function toAddress(bytes bytesAddress) internal pure returns (address addr)
```

_Converts a bytes address to an address type._

#### Parameters

| Name         | Type  | Description                            |
| ------------ | ----- | -------------------------------------- |
| bytesAddress | bytes | The bytes representation of an address |

#### Return Values

| Name | Type    | Description           |
| ---- | ------- | --------------------- |
| addr | address | The converted address |

### toBytes

```solidity
function toBytes(address addr) internal pure returns (bytes bytesAddress)
```

_Converts an address to bytes._

#### Parameters

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| addr | address | The address to be converted |

#### Return Values

| Name         | Type  | Description                             |
| ------------ | ----- | --------------------------------------- |
| bytesAddress | bytes | The bytes representation of the address |

## RemoteAddressValidator

_Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract_

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

Returns true if the gateway delivers token to this chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor(address _interchainTokenServiceAddress) public
```

_Constructs the RemoteAddressValidator contract, both array parameters must be equal in length_

#### Parameters

| Name                            | Type    | Description                             |
| ------------------------------- | ------- | --------------------------------------- |
| \_interchainTokenServiceAddress | address | Address of the interchain token service |

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### \_setup

```solidity
function _setup(bytes params) internal
```

### \_lowerCase

```solidity
function _lowerCase(string s) internal pure returns (string)
```

_Converts a string to lower case_

#### Parameters

| Name | Type   | Description                  |
| ---- | ------ | ---------------------------- |
| s    | string | Input string to be converted |

#### Return Values

| Name | Type   | Description                                  |
| ---- | ------ | -------------------------------------------- |
| [0]  | string | string lowercase version of the input string |

### validateSender

```solidity
function validateSender(string sourceChain, string sourceAddress) external view returns (bool)
```

_Validates that the sender is a valid interchain token service address_

#### Parameters

| Name          | Type   | Description                       |
| ------------- | ------ | --------------------------------- |
| sourceChain   | string | Source chain of the transaction   |
| sourceAddress | string | Source address of the transaction |

#### Return Values

| Name | Type | Description                                           |
| ---- | ---- | ----------------------------------------------------- |
| [0]  | bool | bool true if the sender is validated, false otherwise |

### addTrustedAddress

```solidity
function addTrustedAddress(string chain, string addr) public
```

_Adds a trusted interchain token service address for the specified chain_

#### Parameters

| Name  | Type   | Description                                  |
| ----- | ------ | -------------------------------------------- |
| chain | string | Chain name of the interchain token service   |
| addr  | string | Interchain token service address to be added |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string chain) external
```

_Removes a trusted interchain token service address_

#### Parameters

| Name  | Type   | Description                                              |
| ----- | ------ | -------------------------------------------------------- |
| chain | string | Chain name of the interchain token service to be removed |

### addGatewaySupportedChains

```solidity
function addGatewaySupportedChains(string[] chainNames) external
```

_Adds chains that are supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                  |
| ---------- | -------- | -------------------------------------------- |
| chainNames | string[] | List of chain names to be added as supported |

### removeGatewaySupportedChains

```solidity
function removeGatewaySupportedChains(string[] chainNames) external
```

_Removes chains that are no longer supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                    |
| ---------- | -------- | ---------------------------------------------- |
| chainNames | string[] | List of chain names to be removed as supported |

### getRemoteAddress

```solidity
function getRemoteAddress(string chainName) external view returns (string remoteAddress)
```

_Fetches the interchain token service address for the specified chain_

#### Parameters

| Name      | Type   | Description       |
| --------- | ------ | ----------------- |
| chainName | string | Name of the chain |

#### Return Values

| Name          | Type   | Description                                              |
| ------------- | ------ | -------------------------------------------------------- |
| remoteAddress | string | Interchain token service address for the specified chain |

## RemoteAddressValidatorProxy

_Proxy contract for the RemoteAddressValidator contract. Inherits from the Proxy contract._

### constructor

```solidity
constructor(address implementationAddress, address owner, bytes params) public
```

_Constructs the RemoteAddressValidatorProxy contract._

#### Parameters

| Name                  | Type    | Description                                                            |
| --------------------- | ------- | ---------------------------------------------------------------------- |
| implementationAddress | address | Address of the RemoteAddressValidator implementation                   |
| owner                 | address | Address of the owner of the proxy                                      |
| params                | bytes   | The params to be passed to the \_setup function of the implementation. |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

_Override for the `contractId` function in Proxy. Returns a unique identifier for this contract._

#### Return Values

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| [0]  | bytes32 | bytes32 Identifier for this contract. |

## ExpressCallHandler

_Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface._

### PREFIX_EXPRESS_RECEIVE_TOKEN

```solidity
uint256 PREFIX_EXPRESS_RECEIVE_TOKEN
```

### PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA

```solidity
uint256 PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA
```

### \_getExpressReceiveTokenSlot

```solidity
function _getExpressReceiveTokenSlot(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) internal pure returns (uint256 slot)
```

Calculates the unique slot for a given express token transfer.

#### Parameters

| Name               | Type    | Description                             |
| ------------------ | ------- | --------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent          |
| destinationAddress | address | The address of the recipient            |
| amount             | uint256 | The amount of tokens to be sent         |
| commandId          | bytes32 | The unique hash for this token transfer |

#### Return Values

| Name | Type    | Description                                 |
| ---- | ------- | ------------------------------------------- |
| slot | uint256 | The calculated slot for this token transfer |

### \_getExpressReceiveTokenWithDataSlot

```solidity
function _getExpressReceiveTokenWithDataSlot(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) internal pure returns (uint256 slot)
```

Calculates the unique slot for a given token transfer with data

#### Parameters

| Name               | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent                           |
| sourceChain        | string  | The chain from which the token will be sent              |
| sourceAddress      | bytes   | The originating address of the token on the source chain |
| destinationAddress | address | The address of the recipient on the destination chain    |
| amount             | uint256 | The amount of tokens to be sent                          |
| data               | bytes   | The data associated with the token transfer              |
| commandId          | bytes32 | The unique hash for this token transfer                  |

#### Return Values

| Name | Type    | Description                                 |
| ---- | ------- | ------------------------------------------- |
| slot | uint256 | The calculated slot for this token transfer |

### \_setExpressReceiveToken

```solidity
function _setExpressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId, address expressCaller) internal
```

Stores the address of the express caller at the storage slot determined by \_getExpressSendTokenSlot

#### Parameters

| Name               | Type    | Description                             |
| ------------------ | ------- | --------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent          |
| destinationAddress | address | The address of the recipient            |
| amount             | uint256 | The amount of tokens to be sent         |
| commandId          | bytes32 | The unique hash for this token transfer |
| expressCaller      | address | The address of the express caller       |

### \_setExpressReceiveTokenWithData

```solidity
function _setExpressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId, address expressCaller) internal
```

Stores the address of the express caller for a given token transfer with data at
the storage slot determined by \_getExpressSendTokenWithDataSlot

#### Parameters

| Name               | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent                           |
| sourceChain        | string  | The chain from which the token will be sent              |
| sourceAddress      | bytes   | The originating address of the token on the source chain |
| destinationAddress | address | The address of the recipient on the destination chain    |
| amount             | uint256 | The amount of tokens to be sent                          |
| data               | bytes   | The data associated with the token transfer              |
| commandId          | bytes32 | The unique hash for this token transfer                  |
| expressCaller      | address | The address of the express caller                        |

### getExpressReceiveToken

```solidity
function getExpressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) public view returns (address expressCaller)
```

Gets the address of the express caller for a specific token transfer

#### Parameters

| Name               | Type    | Description                             |
| ------------------ | ------- | --------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent          |
| destinationAddress | address | The address of the recipient            |
| amount             | uint256 | The amount of tokens to be sent         |
| commandId          | bytes32 | The unique hash for this token transfer |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

### getExpressReceiveTokenWithData

```solidity
function getExpressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) public view returns (address expressCaller)
```

Gets the address of the express caller for a specific token transfer with data

#### Parameters

| Name               | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent                           |
| sourceChain        | string  | The chain from which the token will be sent              |
| sourceAddress      | bytes   | The originating address of the token on the source chain |
| destinationAddress | address | The address of the recipient on the destination chain    |
| amount             | uint256 | The amount of tokens to be sent                          |
| data               | bytes   | The data associated with the token transfer              |
| commandId          | bytes32 | The unique hash for this token transfer                  |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

### \_popExpressReceiveToken

```solidity
function _popExpressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) internal returns (address expressCaller)
```

Removes the express caller from storage for a specific token transfer, if it exists.

#### Parameters

| Name               | Type    | Description                             |
| ------------------ | ------- | --------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent          |
| destinationAddress | address | The address of the recipient            |
| amount             | uint256 | The amount of tokens to be sent         |
| commandId          | bytes32 | The unique hash for this token transfer |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

### \_popExpressReceiveTokenWithData

```solidity
function _popExpressReceiveTokenWithData(bytes32 tokenId, string sourceChain, bytes sourceAddress, address destinationAddress, uint256 amount, bytes data, bytes32 commandId) internal returns (address expressCaller)
```

Removes the express caller from storage for a specific token transfer with data, if it exists.

#### Parameters

| Name               | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| tokenId            | bytes32 | The ID of the token being sent                           |
| sourceChain        | string  | The chain from which the token will be sent              |
| sourceAddress      | bytes   | The originating address of the token on the source chain |
| destinationAddress | address | The address of the recipient on the destination chain    |
| amount             | uint256 | The amount of tokens to be sent                          |
| data               | bytes   | The data associated with the token transfer              |
| commandId          | bytes32 | The unique hash for this token transfer                  |

#### Return Values

| Name          | Type    | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| expressCaller | address | The address of the express caller for this token transfer |

## Multicall

This contract is a multi-functional smart contract which allows for multiple
contract calls in a single transaction.

### MulticallFailed

```solidity
error MulticallFailed(bytes err)
```

### multicall

```solidity
function multicall(bytes[] data) public payable returns (bytes[] results)
```

Performs multiple delegate calls and returns the results of all calls as an array

_This function requires that the contract has sufficient balance for the delegate calls.
If any of the calls fail, the function will revert with the failure message._

#### Parameters

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| data | bytes[] | An array of encoded function calls |

#### Return Values

| Name    | Type    | Description                                               |
| ------- | ------- | --------------------------------------------------------- |
| results | bytes[] | An bytes array with the return data of each function call |

## Operatable

_A contract module which provides a basic access control mechanism, where
there is an account (an operator) that can be granted exclusive access to
specific functions. This module is used through inheritance._

### OPERATOR_SLOT

```solidity
uint256 OPERATOR_SLOT
```

### onlyOperator

```solidity
modifier onlyOperator()
```

_Throws a NotOperator custom error if called by any account other than the operator._

### operator

```solidity
function operator() public view returns (address operator_)
```

Get the address of the operator

#### Return Values

| Name       | Type    | Description     |
| ---------- | ------- | --------------- |
| operator\_ | address | of the operator |

### \_setOperator

```solidity
function _setOperator(address operator_) internal
```

_Internal function that stores the new operator address in the operator storage slot_

#### Parameters

| Name       | Type    | Description                     |
| ---------- | ------- | ------------------------------- |
| operator\_ | address | The address of the new operator |

### transferOperatorship

```solidity
function transferOperatorship(address operator_) external
```

Change the operator of the contract

_Can only be called by the current operator_

#### Parameters

| Name       | Type    | Description                     |
| ---------- | ------- | ------------------------------- |
| operator\_ | address | The address of the new operator |

## Pausable

This contract provides a mechanism to halt the execution of specific functions
if a pause condition is activated.

### PAUSE_SLOT

```solidity
uint256 PAUSE_SLOT
```

### notPaused

```solidity
modifier notPaused()
```

A modifier that throws a Paused custom error if the contract is paused

_This modifier should be used with functions that can be paused_

### isPaused

```solidity
function isPaused() public view returns (bool paused)
```

Check if the contract is paused

#### Return Values

| Name   | Type | Description                                                               |
| ------ | ---- | ------------------------------------------------------------------------- |
| paused | bool | A boolean representing the pause status. True if paused, false otherwise. |

### \_setPaused

```solidity
function _setPaused(bool paused) internal
```

Sets the pause status of the contract

_This is an internal function, meaning it can only be called from within the contract itself
or from derived contracts._

#### Parameters

| Name   | Type | Description          |
| ------ | ---- | -------------------- |
| paused | bool | The new pause status |

## InterchainTokenExecutable

### NotService

```solidity
error NotService()
```

### interchainTokenService

```solidity
address interchainTokenService
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
function executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

This will be called after the tokens arrive to this contract

_You are revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name          | Type    | Description                                                                                              |
| ------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| sourceChain   | string  | the name of the source chain                                                                             |
| sourceAddress | bytes   | the address that sent the contract call                                                                  |
| data          | bytes   | the data to be proccessed                                                                                |
| tokenId       | bytes32 | the tokenId of the token manager managing the token. You can access it's address by querying the service |
| amount        | uint256 | the amount of token that was sent                                                                        |

### \_executeWithInterchainToken

```solidity
function _executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) internal virtual
```

## InterchainTokenExpressExecutable

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

### expressExecuteWithInterchainToken

```solidity
function expressExecuteWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) external
```

This will be called after the tokens arrive to this contract

_You are revert unless the msg.sender is the InterchainTokenService_

#### Parameters

| Name          | Type    | Description                                                                                              |
| ------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| sourceChain   | string  | the name of the source chain                                                                             |
| sourceAddress | bytes   | the address that sent the contract call                                                                  |
| data          | bytes   | the data to be proccessed                                                                                |
| tokenId       | bytes32 | the tokenId of the token manager managing the token. You can access it's address by querying the service |
| amount        | uint256 | the amount of token that was sent                                                                        |

## InterchainToken

The implementation ERC20 can be done in any way, however this example assumes that an \_approve internal function exists
that can be used to create approvals, and that `allowance` is a mapping.

_You can skip the `tokenManagerRequiresApproval()` function altogether if you know what it should return for your token._

### getTokenManager

```solidity
function getTokenManager() public view virtual returns (contract ITokenManager tokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name         | Type                   | Description                                                  |
| ------------ | ---------------------- | ------------------------------------------------------------ |
| tokenManager | contract ITokenManager | the TokenManager called to facilitate cross chain transfers. |

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public view virtual returns (bool)
```

Getter function specifying if the tokenManager requires approval to facilitate cross-chain transfers.
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20.
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
TokenManager specifically to do it permissionlessly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description                                                               |
| ---- | ---- | ------------------------------------------------------------------------- |
| [0]  | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name             | Type    | Description                                                                                                                                                                     |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| destinationChain | string  | The destination chain identifier.                                                                                                                                               |
| recipient        | bytes   | The bytes representation of the address of the recipient.                                                                                                                       |
| amount           | uint256 | The amount of token to be transferred.                                                                                                                                          |
| metadata         | bytes   | Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name             | Type    | Description                                                                                                                    |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| sender           | address | the sender of the tokens. They need to have approved `msg.sender` before this is called.                                       |
| destinationChain | string  | the string representation of the destination chain.                                                                            |
| recipient        | bytes   | the bytes representation of the address of the recipient.                                                                      |
| amount           | uint256 | the amount of token to be transferred.                                                                                         |
| metadata         | bytes   | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

## IDistributable

### NotDistributor

```solidity
error NotDistributor()
```

### DistributorshipTransferred

```solidity
event DistributorshipTransferred(address distributor)
```

### distributor

```solidity
function distributor() external view returns (address distributor)
```

Get the address of the distributor

#### Return Values

| Name        | Type    | Description        |
| ----------- | ------- | ------------------ |
| distributor | address | of the distributor |

### transferDistributorship

```solidity
function transferDistributorship(address distributor) external
```

Change the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name        | Type    | Description                        |
| ----------- | ------- | ---------------------------------- |
| distributor | address | The address of the new distributor |

## IERC20BurnableMintable

_Interface of the ERC20 standard as defined in the EIP._

### mint

```solidity
function mint(address to, uint256 amount) external
```

Function to mint new tokens
Can only be called by the distributor address.

#### Parameters

| Name   | Type    | Description                                     |
| ------ | ------- | ----------------------------------------------- |
| to     | address | The address that will receive the minted tokens |
| amount | uint256 | The amount of tokens to mint                    |

### burn

```solidity
function burn(address from, uint256 amount) external
```

Function to burn tokens
Can only be called by the distributor address.

#### Parameters

| Name   | Type    | Description                                 |
| ------ | ------- | ------------------------------------------- |
| from   | address | The address that will have its tokens burnt |
| amount | uint256 | The amount of tokens to burn                |

## IInterchainToken

_Interface of the ERC20 standard as defined in the EIP._

### interchainTransfer

```solidity
function interchainTransfer(string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransfer method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name             | Type    | Description                                                                                                                                                                     |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| destinationChain | string  | The destination chain identifier.                                                                                                                                               |
| recipient        | bytes   | The bytes representation of the address of the recipient.                                                                                                                       |
| amount           | uint256 | The amount of token to be transferred.                                                                                                                                          |
| metadata         | bytes   | Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service. |

### interchainTransferFrom

```solidity
function interchainTransferFrom(address sender, string destinationChain, bytes recipient, uint256 amount, bytes metadata) external payable
```

Implementation of the interchainTransferFrom method

_We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well._

#### Parameters

| Name             | Type    | Description                                                                                                                    |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| sender           | address | the sender of the tokens. They need to have approved `msg.sender` before this is called.                                       |
| destinationChain | string  | the string representation of the destination chain.                                                                            |
| recipient        | bytes   | the bytes representation of the address of the recipient.                                                                      |
| amount           | uint256 | the amount of token to be transferred.                                                                                         |
| metadata         | bytes   | either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer. |

## ILinkerRouter

_Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract_

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

### TrustedAddressAdded

```solidity
event TrustedAddressAdded(string sourceChain, string sourceAddress)
```

### TrustedAddressRemoved

```solidity
event TrustedAddressRemoved(string sourceChain)
```

### GatewaySupportedChainAdded

```solidity
event GatewaySupportedChainAdded(string chain)
```

### GatewaySupportedChainRemoved

```solidity
event GatewaySupportedChainRemoved(string chain)
```

### validateSender

```solidity
function validateSender(string sourceChain, string sourceAddress) external view returns (bool)
```

_Validates that the sender is a valid interchain token service address_

#### Parameters

| Name          | Type   | Description                       |
| ------------- | ------ | --------------------------------- |
| sourceChain   | string | Source chain of the transaction   |
| sourceAddress | string | Source address of the transaction |

#### Return Values

| Name | Type | Description                                           |
| ---- | ---- | ----------------------------------------------------- |
| [0]  | bool | bool true if the sender is validated, false otherwise |

### addTrustedAddress

```solidity
function addTrustedAddress(string sourceChain, string sourceAddress) external
```

_Adds a trusted interchain token service address for the specified chain_

#### Parameters

| Name          | Type   | Description                                  |
| ------------- | ------ | -------------------------------------------- |
| sourceChain   | string | Chain name of the interchain token service   |
| sourceAddress | string | Interchain token service address to be added |

### removeTrustedAddress

```solidity
function removeTrustedAddress(string sourceChain) external
```

_Removes a trusted interchain token service address_

#### Parameters

| Name        | Type   | Description                                              |
| ----------- | ------ | -------------------------------------------------------- |
| sourceChain | string | Chain name of the interchain token service to be removed |

### getRemoteAddress

```solidity
function getRemoteAddress(string chainName) external view returns (string remoteAddress)
```

_Fetches the interchain token service address for the specified chain_

#### Parameters

| Name      | Type   | Description       |
| --------- | ------ | ----------------- |
| chainName | string | Name of the chain |

#### Return Values

| Name          | Type   | Description                                              |
| ------------- | ------ | -------------------------------------------------------- |
| remoteAddress | string | Interchain token service address for the specified chain |

### supportedByGateway

```solidity
function supportedByGateway(string chainName) external view returns (bool)
```

Returns true if the gateway delivers token to this chain.

#### Parameters

| Name      | Type   | Description       |
| --------- | ------ | ----------------- |
| chainName | string | Name of the chain |

### addGatewaySupportedChains

```solidity
function addGatewaySupportedChains(string[] chainNames) external
```

_Adds chains that are supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                  |
| ---------- | -------- | -------------------------------------------- |
| chainNames | string[] | List of chain names to be added as supported |

### removeGatewaySupportedChains

```solidity
function removeGatewaySupportedChains(string[] chainNames) external
```

_Removes chains that are no longer supported by the Axelar gateway_

#### Parameters

| Name       | Type     | Description                                    |
| ---------- | -------- | ---------------------------------------------- |
| chainNames | string[] | List of chain names to be removed as supported |

## InterchainTokenServiceProxy

_Proxy contract for interchain token service contracts. Inherits from the FinalProxy contract._

### constructor

```solidity
constructor(address implementationAddress, address owner, address operator) public
```

_Constructs the InterchainTokenServiceProxy contract._

#### Parameters

| Name                  | Type    | Description                                            |
| --------------------- | ------- | ------------------------------------------------------ |
| implementationAddress | address | Address of the interchain token service implementation |
| owner                 | address | Address of the owner of the proxy                      |
| operator              | address |                                                        |

### contractId

```solidity
function contractId() internal pure returns (bytes32)
```

_Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract._

#### Return Values

| Name | Type    | Description                          |
| ---- | ------- | ------------------------------------ |
| [0]  | bytes32 | bytes32 identifier for this contract |

## TokenManagerProxy

_This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
inherits from FixedProxy from the gmp sdk repo_

### interchainTokenServiceAddress

```solidity
contract IInterchainTokenService interchainTokenServiceAddress
```

### implementationType

```solidity
uint256 implementationType
```

Returns implementation type of this token manager

### tokenId

```solidity
bytes32 tokenId
```

Returns token ID of the token manager.

### constructor

```solidity
constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId_, bytes params) public
```

_Constructs the TokenManagerProxy contract._

#### Parameters

| Name                            | Type    | Description                                                  |
| ------------------------------- | ------- | ------------------------------------------------------------ |
| interchainTokenServiceAddress\_ | address | The address of the interchain token service                  |
| implementationType\_            | uint256 | The token manager type                                       |
| tokenId\_                       | bytes32 | The identifier for the token                                 |
| params                          | bytes   | The initialization parameters for the token manager contract |

### implementation

```solidity
function implementation() public view returns (address impl)
```

_Returns the address of the current implementation._

#### Return Values

| Name | Type    | Description                               |
| ---- | ------- | ----------------------------------------- |
| impl | address | The address of the current implementation |

### \_getImplementation

```solidity
function _getImplementation(contract IInterchainTokenService interchainTokenServiceAddress_, uint256 implementationType_) internal view returns (address impl)
```

_Returns the implementation address from the interchain token service for the provided type._

#### Parameters

| Name                            | Type                             | Description                                 |
| ------------------------------- | -------------------------------- | ------------------------------------------- |
| interchainTokenServiceAddress\_ | contract IInterchainTokenService | The address of the interchain token service |
| implementationType\_            | uint256                          | The token manager type                      |

#### Return Values

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| impl | address | The address of the implementation |

### setup

```solidity
function setup(bytes setupParams) external
```

_Setup function. Empty in this contract._

#### Parameters

| Name        | Type  | Description               |
| ----------- | ----- | ------------------------- |
| setupParams | bytes | Initialization parameters |

### fallback

```solidity
fallback() external payable virtual
```

_Fallback function. Delegates the call to the token manager contract._

### receive

```solidity
receive() external payable virtual
```

_Receive function which allows this contract to receive ether._

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

### \_executeWithInterchainToken

```solidity
function _executeWithInterchainToken(string sourceChain, bytes sourceAddress, bytes data, bytes32 tokenId, uint256 amount) internal
```

## InterchainTokenTest

### tokenManager

```solidity
contract ITokenManager tokenManager
```

### tokenManagerRequiresApproval\_

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
constructor(string name_, string symbol_, uint8 decimals_, address tokenManager_) public
```

### getTokenManager

```solidity
function getTokenManager() public view returns (contract ITokenManager)
```

Getter for the tokenManager used for this token.

_Needs to be overwitten._

#### Return Values

| Name | Type                   | Description |
| ---- | ---------------------- | ----------- |
| [0]  | contract ITokenManager |             |

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public view returns (bool)
```

Getter function specifying if the tokenManager requires approval to facilitate cross-chain transfers.
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20.
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
TokenManager specifically to do it permissionlessly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description                                                               |
| ---- | ---- | ------------------------------------------------------------------------- |
| [0]  | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

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

## ERC20

\_Implementation of the {IERC20} interface.

This implementation is agnostic to the way tokens are created. This means
that a supply mechanism has to be added in a derived contract using {\_mint}.
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
allowances. See {IERC20-approve}.\_

### balanceOf

```solidity
mapping(address => uint256) balanceOf
```

_Returns the amount of tokens owned by `account`._

### allowance

```solidity
mapping(address => mapping(address => uint256)) allowance
```

\_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called.\_

### totalSupply

```solidity
uint256 totalSupply
```

_Returns the amount of tokens in existence._

### transfer

```solidity
function transfer(address recipient, uint256 amount) external virtual returns (bool)
```

\_See {IERC20-transfer}.

Requirements:

-   `recipient` cannot be the zero address.
-   the caller must have a balance of at least `amount`.\_

### approve

```solidity
function approve(address spender, uint256 amount) external virtual returns (bool)
```

\_See {IERC20-approve}.

NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
`transferFrom`. This is semantically equivalent to an infinite approval.

Requirements:

-   `spender` cannot be the zero address.\_

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool)
```

\_See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

Requirements:

-   `sender` and `recipient` cannot be the zero address.
-   `sender` must have a balance of at least `amount`.
-   the caller must have allowance for `sender`'s tokens of at least
    `amount`.\_

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool)
```

\_Atomically increases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

-   `spender` cannot be the zero address.\_

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool)
```

\_Atomically decreases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

-   `spender` cannot be the zero address.
-   `spender` must have allowance for the caller of at least
    `subtractedValue`.\_

### \_transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount) internal virtual
```

\_Moves tokens `amount` from `sender` to `recipient`.

This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

-   `sender` cannot be the zero address.
-   `recipient` cannot be the zero address.
-   `sender` must have a balance of at least `amount`.\_

### \_mint

```solidity
function _mint(address account, uint256 amount) internal virtual
```

\_Creates `amount` tokens and assigns them to `account`, increasing
the total supply.

Emits a {Transfer} event with `from` set to the zero address.

Requirements:

-   `to` cannot be the zero address.\_

### \_burn

```solidity
function _burn(address account, uint256 amount) internal virtual
```

\_Destroys `amount` tokens from `account`, reducing the
total supply.

Emits a {Transfer} event with `to` set to the zero address.

Requirements:

-   `account` cannot be the zero address.
-   `account` must have at least `amount` tokens.\_

### \_approve

```solidity
function _approve(address owner, address spender, uint256 amount) internal virtual
```

\_Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

-   `owner` cannot be the zero address.
-   `spender` cannot be the zero address.\_

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

### DOMAIN_SEPARATOR

```solidity
bytes32 DOMAIN_SEPARATOR
```

_Represents hash of the EIP-712 Domain Separator._

### nonces

```solidity
mapping(address => uint256) nonces
```

_Mapping of nonces for each address._

### \_setDomainTypeSignatureHash

```solidity
function _setDomainTypeSignatureHash(string name) internal
```

Internal function to set the domain type signature hash

#### Parameters

| Name | Type   | Description    |
| ---- | ------ | -------------- |
| name | string | The token name |

### permit

```solidity
function permit(address issuer, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

Permit the designated spender to spend the holder's tokens

_The permit function is used to allow a holder to designate a spender
to spend tokens on their behalf via a signed message._

#### Parameters

| Name     | Type    | Description                                       |
| -------- | ------- | ------------------------------------------------- |
| issuer   | address | The address of the token holder                   |
| spender  | address | The address of the designated spender             |
| value    | uint256 | The number of tokens to be spent                  |
| deadline | uint256 | The time at which the permission to spend expires |
| v        | uint8   | The recovery id of the signature                  |
| r        | bytes32 | Half of the ECDSA signature pair                  |
| s        | bytes32 | Half of the ECDSA signature pair                  |

## StandardizedToken

This contract implements a standardized token which extends InterchainToken functionality.
This contract also inherits Distributable and Implementation logic.

### tokenManager

```solidity
address tokenManager
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

### CONTRACT_ID

```solidity
bytes32 CONTRACT_ID
```

### contractId

```solidity
function contractId() external pure returns (bytes32)
```

Getter for the contract id.

### getTokenManager

```solidity
function getTokenManager() public view returns (contract ITokenManager)
```

Returns the token manager for this token

#### Return Values

| Name | Type                   | Description                              |
| ---- | ---------------------- | ---------------------------------------- |
| [0]  | contract ITokenManager | ITokenManager The token manager contract |

### setup

```solidity
function setup(bytes params) external
```

Setup function to initialize contract parameters

#### Parameters

| Name   | Type  | Description                                                                                                                          |
| ------ | ----- | ------------------------------------------------------------------------------------------------------------------------------------ |
| params | bytes | The setup parameters in bytes The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo |

### mint

```solidity
function mint(address account, uint256 amount) external
```

Function to mint new tokens
Can only be called by the distributor address.

#### Parameters

| Name    | Type    | Description                                     |
| ------- | ------- | ----------------------------------------------- |
| account | address | The address that will receive the minted tokens |
| amount  | uint256 | The amount of tokens to mint                    |

### burn

```solidity
function burn(address account, uint256 amount) external
```

Function to burn tokens
Can only be called by the distributor address.

#### Parameters

| Name    | Type    | Description                                 |
| ------- | ------- | ------------------------------------------- |
| account | address | The address that will have its tokens burnt |
| amount  | uint256 | The amount of tokens to burn                |

## StandardizedTokenLockUnlock

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public pure returns (bool)
```

Getter function specifying if the tokenManager requires approval to facilitate cross-chain transfers.
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20.
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
TokenManager specifically to do it permissionlessly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description                                                               |
| ---- | ---- | ------------------------------------------------------------------------- |
| [0]  | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

## StandardizedTokenMintBurn

### tokenManagerRequiresApproval

```solidity
function tokenManagerRequiresApproval() public pure returns (bool)
```

Getter function specifying if the tokenManager requires approval to facilitate cross-chain transfers.
Usually, only mint/burn tokenManagers do not need approval.

_The return value depends on the implementation of ERC20.
In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
TokenManager specifically to do it permissionlessly.
On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager_

#### Return Values

| Name | Type | Description                                                               |
| ---- | ---- | ------------------------------------------------------------------------- |
| [0]  | bool | tokenManager the TokenManager called to facilitate cross chain transfers. |

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

Constructs the TokenManager contract.

#### Parameters

| Name                     | Type    | Description                                 |
| ------------------------ | ------- | ------------------------------------------- |
| interchainTokenService\_ | address | The address of the interchain token service |

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
function tokenAddress() public view virtual returns (address)
```

A function that should return the address of the token.
Must be overridden in the inheriting contract.

#### Return Values

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| [0]  | address | address address of the token. |

### setup

```solidity
function setup(bytes params) external
```

_This function should only be called by the proxy, and only once from the proxy constructor_

#### Parameters

| Name   | Type  | Description                                                                                                                                                                                                                                     |
| ------ | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| params | bytes | the parameters to be used to initialize the TokenManager. The exact format depends on the type of TokenManager used but the first 32 bytes are reserved for the address of the operator, stored as bytes (to be compatible with non-EVM chains) |

### sendToken

```solidity
function sendToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable virtual
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.

#### Parameters

| Name               | Type    | Description                                   |
| ------------------ | ------- | --------------------------------------------- |
| destinationChain   | string  | the name of the chain to send tokens to.      |
| destinationAddress | bytes   | the address of the user to send tokens to.    |
| amount             | uint256 | the amount of tokens to take from msg.sender. |
| metadata           | bytes   |                                               |

### callContractWithInterchainToken

```solidity
function callContractWithInterchainToken(string destinationChain, bytes destinationAddress, uint256 amount, bytes data) external payable virtual
```

Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.

#### Parameters

| Name               | Type    | Description                                   |
| ------------------ | ------- | --------------------------------------------- |
| destinationChain   | string  | the name of the chain to send tokens to.      |
| destinationAddress | bytes   | the address of the user to send tokens to.    |
| amount             | uint256 | the amount of tokens to take from msg.sender. |
| data               | bytes   | the data to pass to the destination contract. |

### transmitInterchainTransfer

```solidity
function transmitInterchainTransfer(address sender, string destinationChain, bytes destinationAddress, uint256 amount, bytes metadata) external payable virtual
```

Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.

#### Parameters

| Name               | Type    | Description                                                  |
| ------------------ | ------- | ------------------------------------------------------------ |
| sender             | address | the address of the user paying for the cross chain transfer. |
| destinationChain   | string  | the name of the chain to send tokens to.                     |
| destinationAddress | bytes   | the address of the user to send tokens to.                   |
| amount             | uint256 | the amount of tokens to take from msg.sender.                |
| metadata           | bytes   |                                                              |

### giveToken

```solidity
function giveToken(address destinationAddress, uint256 amount) external returns (uint256)
```

This function gives token to a specified address. Can only be called by the service.

#### Parameters

| Name               | Type    | Description                    |
| ------------------ | ------- | ------------------------------ |
| destinationAddress | address | the address to give tokens to. |
| amount             | uint256 | the amount of token to give.   |

#### Return Values

| Name | Type    | Description                                                                                                                         |
| ---- | ------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee. |

### setFlowLimit

```solidity
function setFlowLimit(uint256 flowLimit) external
```

This function sets the flow limit for this TokenManager. Can only be called by the operator.

#### Parameters

| Name      | Type    | Description                                                                                        |
| --------- | ------- | -------------------------------------------------------------------------------------------------- |
| flowLimit | uint256 | the maximum difference between the tokens flowing in and/or out at any given interval of time (6h) |

### \_takeToken

```solidity
function _takeToken(address from, uint256 amount) internal virtual returns (uint256)
```

Transfers tokens from a specific address to this contract.
Must be overridden in the inheriting contract.

#### Parameters

| Name   | Type    | Description                                    |
| ------ | ------- | ---------------------------------------------- |
| from   | address | The address from which the tokens will be sent |
| amount | uint256 | The amount of tokens to receive                |

#### Return Values

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| [0]  | uint256 | uint amount of tokens received |

### \_giveToken

```solidity
function _giveToken(address receiver, uint256 amount) internal virtual returns (uint256)
```

Transfers tokens from this contract to a specific address.
Must be overridden in the inheriting contract.

#### Parameters

| Name   | Type    | Description                                  |
| ------ | ------- | -------------------------------------------- |
| from   | address | The address to which the tokens will be sent |
| amount | uint256 | The amount of tokens to send                 |

#### Return Values

| Name | Type    | Description                |
| ---- | ------- | -------------------------- |
| [0]  | uint256 | uint amount of tokens sent |

### \_setup

```solidity
function _setup(bytes params) internal virtual
```

_Additional setup logic to perform
Must be overridden in the inheriting contract._

#### Parameters

| Name   | Type  | Description          |
| ------ | ----- | -------------------- |
| params | bytes | The setup parameters |

### \_getTokenId

```solidity
function _getTokenId() internal view returns (bytes32 tokenId)
```

Gets the token ID from the token manager proxy.

#### Return Values

| Name    | Type    | Description         |
| ------- | ------- | ------------------- |
| tokenId | bytes32 | The ID of the token |

## TokenManagerAddressStorage

This contract extends the TokenManager contract and provides additional functionality to store and retrieve
the token address using a predetermined storage slot

### constructor

```solidity
constructor(address interchainTokenService_) internal
```

_Creates an instance of the TokenManagerAddressStorage contract._

#### Parameters

| Name                     | Type    | Description                                          |
| ------------------------ | ------- | ---------------------------------------------------- |
| interchainTokenService\_ | address | The address of the interchain token service contract |

### TOKEN_ADDRESS_SLOT

```solidity
uint256 TOKEN_ADDRESS_SLOT
```

### tokenAddress

```solidity
function tokenAddress() public view returns (address tokenAddress_)
```

_Reads the stored token address from the predetermined storage slot_

#### Return Values

| Name           | Type    | Description              |
| -------------- | ------- | ------------------------ |
| tokenAddress\_ | address | The address of the token |

### \_setTokenAddress

```solidity
function _setTokenAddress(address tokenAddress_) internal
```

_Stores the token address in the predetermined storage slot_

#### Parameters

| Name           | Type    | Description                       |
| -------------- | ------- | --------------------------------- |
| tokenAddress\_ | address | The address of the token to store |

## TokenManagerLiquidityPool

This contract is a an implementation of TokenManager that stores all tokens in a separate liquity pool
rather than within itself.

_This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
It uses the Axelar SDK to safely transfer tokens._

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

| Name                     | Type    | Description                                          |
| ------------------------ | ------- | ---------------------------------------------------- |
| interchainTokenService\_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### \_setup

```solidity
function _setup(bytes params) internal
```

_Sets up the token address and liquidity pool address._

#### Parameters

| Name   | Type  | Description                                                                                             |
| ------ | ----- | ------------------------------------------------------------------------------------------------------- |
| params | bytes | The setup parameters in bytes. Should be encoded with the token address and the liquidity pool address. |

### \_setLiquidityPool

```solidity
function _setLiquidityPool(address liquidityPool_) internal
```

_Stores the liquidity pool address at a specific storage slot_

#### Parameters

| Name            | Type    | Description                       |
| --------------- | ------- | --------------------------------- |
| liquidityPool\_ | address | The address of the liquidity pool |

### liquidityPool

```solidity
function liquidityPool() public view returns (address liquidityPool_)
```

_Reads the stored liquidity pool address from the specified storage slot_

#### Return Values

| Name            | Type    | Description                       |
| --------------- | ------- | --------------------------------- |
| liquidityPool\_ | address | The address of the liquidity pool |

### setLiquidityPool

```solidity
function setLiquidityPool(address newLiquidityPool) external
```

_Updates the address of the liquidity pool. Can only be called by the operator._

#### Parameters

| Name             | Type    | Description                           |
| ---------------- | ------- | ------------------------------------- |
| newLiquidityPool | address | The new address of the liquidity pool |

### \_takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from a specified address to the liquidity pool._

#### Parameters

| Name   | Type    | Description                         |
| ------ | ------- | ----------------------------------- |
| from   | address | The address to transfer tokens from |
| amount | uint256 | The amount of tokens to transfer    |

#### Return Values

| Name | Type    | Description                                                                                   |
| ---- | ------- | --------------------------------------------------------------------------------------------- |
| [0]  | uint256 | uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens. |

### \_giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from the liquidity pool to a specified address._

#### Parameters

| Name   | Type    | Description                       |
| ------ | ------- | --------------------------------- |
| to     | address | The address to transfer tokens to |
| amount | uint256 | The amount of tokens to transfer  |

#### Return Values

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| [0]  | uint256 | uint The actual amount of tokens transferred |

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

| Name                     | Type    | Description                                          |
| ------------------------ | ------- | ---------------------------------------------------- |
| interchainTokenService\_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### \_setup

```solidity
function _setup(bytes params) internal
```

_Sets up the token address._

#### Parameters

| Name   | Type  | Description                                                              |
| ------ | ----- | ------------------------------------------------------------------------ |
| params | bytes | The setup parameters in bytes. Should be encoded with the token address. |

### \_takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from a specified address to this contract._

#### Parameters

| Name   | Type    | Description                         |
| ------ | ------- | ----------------------------------- |
| from   | address | The address to transfer tokens from |
| amount | uint256 | The amount of tokens to transfer    |

#### Return Values

| Name | Type    | Description                                                                                   |
| ---- | ------- | --------------------------------------------------------------------------------------------- |
| [0]  | uint256 | uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens. |

### \_giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Transfers a specified amount of tokens from this contract to a specified address._

#### Parameters

| Name   | Type    | Description                       |
| ------ | ------- | --------------------------------- |
| to     | address | The address to transfer tokens to |
| amount | uint256 | The amount of tokens to transfer  |

#### Return Values

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| [0]  | uint256 | uint The actual amount of tokens transferred |

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

| Name                     | Type    | Description                                          |
| ------------------------ | ------- | ---------------------------------------------------- |
| interchainTokenService\_ | address | The address of the interchain token service contract |

### implementationType

```solidity
function implementationType() external pure returns (uint256)
```

A function that should return the implementation type of the token manager.

### \_setup

```solidity
function _setup(bytes params) internal
```

_Sets up the token address._

#### Parameters

| Name   | Type  | Description                                                              |
| ------ | ----- | ------------------------------------------------------------------------ |
| params | bytes | The setup parameters in bytes. Should be encoded with the token address. |

### \_takeToken

```solidity
function _takeToken(address from, uint256 amount) internal returns (uint256)
```

_Burns the specified amount of tokens from a particular address._

#### Parameters

| Name   | Type    | Description                 |
| ------ | ------- | --------------------------- |
| from   | address | Address to burn tokens from |
| amount | uint256 | Amount of tokens to burn    |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | uint Amount of tokens burned |

### \_giveToken

```solidity
function _giveToken(address to, uint256 amount) internal returns (uint256)
```

_Mints the specified amount of tokens to a particular address_

#### Parameters

| Name   | Type    | Description               |
| ------ | ------- | ------------------------- |
| to     | address | Address to mint tokens to |
| amount | uint256 | Amount of tokens to mint  |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | uint Amount of tokens minted |

## Distributable

_A contract module which provides a basic access control mechanism, where
there is an account (a distributor) that can be granted exclusive access to
specific functions. This module is used through inheritance._

### DISTRIBUTOR_SLOT

```solidity
uint256 DISTRIBUTOR_SLOT
```

### onlyDistributor

```solidity
modifier onlyDistributor()
```

_Throws a NotDistributor custom error if called by any account other than the distributor._

### distributor

```solidity
function distributor() public view returns (address distributor_)
```

Get the address of the distributor

#### Return Values

| Name          | Type    | Description        |
| ------------- | ------- | ------------------ |
| distributor\_ | address | of the distributor |

### \_setDistributor

```solidity
function _setDistributor(address distributor_) internal
```

_Internal function that stores the new distributor address in the correct storage slot_

#### Parameters

| Name          | Type    | Description                        |
| ------------- | ------- | ---------------------------------- |
| distributor\_ | address | The address of the new distributor |

### transferDistributorship

```solidity
function transferDistributorship(address distributor_) external
```

Change the distributor of the contract

_Can only be called by the current distributor_

#### Parameters

| Name          | Type    | Description                        |
| ------------- | ------- | ---------------------------------- |
| distributor\_ | address | The address of the new distributor |

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

### getFlowLimit

```solidity
function getFlowLimit() public view returns (uint256 flowLimit)
```

Returns the current flow limit

#### Return Values

| Name      | Type    | Description                  |
| --------- | ------- | ---------------------------- |
| flowLimit | uint256 | The current flow limit value |

### \_setFlowLimit

```solidity
function _setFlowLimit(uint256 flowLimit) internal
```

_Internal function to set the flow limit_

#### Parameters

| Name      | Type    | Description                        |
| --------- | ------- | ---------------------------------- |
| flowLimit | uint256 | The value to set the flow limit to |

### \_getFlowOutSlot

```solidity
function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow out amount for a specific epoch_

#### Parameters

| Name  | Type    | Description                              |
| ----- | ------- | ---------------------------------------- |
| epoch | uint256 | The epoch to get the flow out amount for |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| slot | uint256 | The slot to get the flow out amount from |

### \_getFlowInSlot

```solidity
function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot)
```

_Returns the slot which is used to get the flow in amount for a specific epoch_

#### Parameters

| Name  | Type    | Description                             |
| ----- | ------- | --------------------------------------- |
| epoch | uint256 | The epoch to get the flow in amount for |

#### Return Values

| Name | Type    | Description                             |
| ---- | ------- | --------------------------------------- |
| slot | uint256 | The slot to get the flow in amount from |

### getFlowOutAmount

```solidity
function getFlowOutAmount() external view returns (uint256 flowOutAmount)
```

Returns the current flow out amount

#### Return Values

| Name          | Type    | Description                 |
| ------------- | ------- | --------------------------- |
| flowOutAmount | uint256 | The current flow out amount |

### getFlowInAmount

```solidity
function getFlowInAmount() external view returns (uint256 flowInAmount)
```

Returns the current flow in amount

#### Return Values

| Name         | Type    | Description                |
| ------------ | ------- | -------------------------- |
| flowInAmount | uint256 | The current flow in amount |

### \_addFlow

```solidity
function _addFlow(uint256 flowLimit, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal
```

_Adds a flow amount while ensuring it does not exceed the flow limit_

#### Parameters

| Name          | Type    | Description                          |
| ------------- | ------- | ------------------------------------ |
| flowLimit     | uint256 |                                      |
| slotToAdd     | uint256 | The slot to add the flow to          |
| slotToCompare | uint256 | The slot to compare the flow against |
| flowAmount    | uint256 | The flow amount to add               |

### \_addFlowOut

```solidity
function _addFlowOut(uint256 flowOutAmount) internal
```

_Adds a flow out amount_

#### Parameters

| Name          | Type    | Description                |
| ------------- | ------- | -------------------------- |
| flowOutAmount | uint256 | The flow out amount to add |

### \_addFlowIn

```solidity
function _addFlowIn(uint256 flowInAmount) internal
```

_Adds a flow in amount_

#### Parameters

| Name         | Type    | Description               |
| ------------ | ------- | ------------------------- |
| flowInAmount | uint256 | The flow in amount to add |

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

### setup

```solidity
function setup(bytes params) external virtual
```

Initializes contract parameters.
This function is intended to be overridden by derived contracts.
The overriding function must have the onlyProxy modifier.

#### Parameters

| Name   | Type  | Description                                  |
| ------ | ----- | -------------------------------------------- |
| params | bytes | The parameters to be used for initialization |

## TokenManagerDeployer

This contract is used to deploy new instances of the TokenManagerProxy contract.

### deployer

```solidity
contract Create3Deployer deployer
```

Getter for the Create3Deployer.

### constructor

```solidity
constructor(address deployer_) public
```

Constructor for the TokenManagerDeployer contract

#### Parameters

| Name       | Type    | Description                             |
| ---------- | ------- | --------------------------------------- |
| deployer\_ | address | Address of the Create3Deployer contract |

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable
```

Deploys a new instance of the TokenManagerProxy contract

#### Parameters

| Name               | Type    | Description                                                  |
| ------------------ | ------- | ------------------------------------------------------------ |
| tokenId            | bytes32 | The unique identifier for the token                          |
| implementationType | uint256 | Token manager implementation type                            |
| params             | bytes   | Additional parameters used in the setup of the token manager |

## IStandardizedToken

This contract implements a standardized token which extends InterchainToken functionality.
This contract also inherits Distributable and Implementation logic.

### contractId

```solidity
function contractId() external view returns (bytes32)
```

Returns the contract id, which a proxy can check to ensure no false implementation was used.

### setup

```solidity
function setup(bytes params) external
```

Called by the proxy to setup itself.

_This should be hidden by the proxy._

#### Parameters

| Name   | Type  | Description                                 |
| ------ | ----- | ------------------------------------------- |
| params | bytes | the data to be used for the initialization. |

## IStandardizedTokenProxy

_Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy._

### WrongImplementation

```solidity
error WrongImplementation()
```

### contractId

```solidity
function contractId() external view returns (bytes32)
```

Returns the contract id, which a proxy can check to ensure no false implementation was used.

## StandardizedTokenProxy

_Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy._

### contractId

```solidity
bytes32 contractId
```

Returns the contract id, which a proxy can check to ensure no false implementation was used.

### constructor

```solidity
constructor(address implementationAddress, bytes params) public
```

_Constructs the StandardizedTokenProxy contract._

#### Parameters

| Name                  | Type    | Description                                                  |
| --------------------- | ------- | ------------------------------------------------------------ |
| implementationAddress | address | Address of the StandardizedToken implementation              |
| params                | bytes   | Initialization parameters for the StandardizedToken contract |

## StandardizedTokenDeployer

This contract is used to deploy new instances of the StandardizedTokenProxy contract.

### deployer

```solidity
contract Create3Deployer deployer
```

Getter for the Create3Deployer.

### implementationMintBurnAddress

```solidity
address implementationMintBurnAddress
```

### implementationLockUnlockAddress

```solidity
address implementationLockUnlockAddress
```

### constructor

```solidity
constructor(address deployer_, address implementationLockUnlockAddress_, address implementationMintBurnAddress_) public
```

Constructor for the StandardizedTokenDeployer contract

#### Parameters

| Name                              | Type    | Description                                         |
| --------------------------------- | ------- | --------------------------------------------------- |
| deployer\_                        | address | Address of the Create3Deployer contract             |
| implementationLockUnlockAddress\_ | address | Address of the StandardizedTokenLockUnlock contract |
| implementationMintBurnAddress\_   | address | Address of the StandardizedTokenMintBurn contract   |

### deployStandardizedToken

```solidity
function deployStandardizedToken(bytes32 salt, address tokenManager, address distributor, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo) external payable
```

Deploys a new instance of the StandardizedTokenProxy contract

#### Parameters

| Name         | Type    | Description                        |
| ------------ | ------- | ---------------------------------- |
| salt         | bytes32 | The salt used by Create3Deployer   |
| tokenManager | address | Address of the token manager       |
| distributor  | address | Address of the distributor         |
| name         | string  | Name of the token                  |
| symbol       | string  | Symbol of the token                |
| decimals     | uint8   | Decimals of the token              |
| mintAmount   | uint256 | Amount of tokens to mint initially |
| mintTo       | address | Address to mint initial tokens to  |
