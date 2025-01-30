# Solidity API

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

### TokenSymbolEmpty

```solidity
error TokenSymbolEmpty()
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

