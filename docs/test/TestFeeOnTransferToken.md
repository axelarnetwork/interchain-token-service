# Solidity API

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

