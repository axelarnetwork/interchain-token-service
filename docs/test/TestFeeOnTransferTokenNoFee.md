# Solidity API

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

