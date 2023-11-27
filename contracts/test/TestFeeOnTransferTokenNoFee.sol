// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TestFeeOnTransferToken } from './TestFeeOnTransferToken.sol';

contract TestFeeOnTransferTokenNoFee is TestFeeOnTransferToken {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address tokenManagerAddress
    ) TestFeeOnTransferToken(name_, symbol_, decimals_, tokenManagerAddress) {}

    // no fee
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (sender == address(0) || recipient == address(0)) revert InvalidAccount();

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}
