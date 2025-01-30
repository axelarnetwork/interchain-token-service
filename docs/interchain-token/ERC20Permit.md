# Solidity API

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

