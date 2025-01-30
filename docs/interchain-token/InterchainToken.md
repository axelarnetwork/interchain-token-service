# Solidity API

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

