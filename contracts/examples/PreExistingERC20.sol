// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from '../token-implementations/ERC20.sol';

contract PreExistingERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }
}