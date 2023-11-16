// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from '../interchain-token/ERC20.sol';

contract TestERC20 is ERC20 {
    function transferFromWithoutApprove(address sender, address recipient, uint256 amount) external virtual returns (bool) {
        _transfer(sender, recipient, amount);

        return true;
    }
}
