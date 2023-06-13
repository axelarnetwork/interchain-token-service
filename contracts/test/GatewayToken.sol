// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ERC20 } from '../utils/ERC20.sol';
import { Distributable } from '../utils/Distributable.sol';

contract GatewayToken is ERC20, Distributable {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _setDistributor(msg.sender);
    }

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
