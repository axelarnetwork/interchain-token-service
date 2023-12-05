// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from '../interchain-token/ERC20.sol';
import { Minter } from '../utils/Minter.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';

contract TestMintableBurnableERC20 is ERC20, Minter, IERC20MintableBurnable {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _addMinter(msg.sender);
    }

    function mint(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        _burn(account, amount);
    }
}
