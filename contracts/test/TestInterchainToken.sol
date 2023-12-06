// SPDX-License-Identifier: MIT

// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.0;

import { InterchainToken } from '../interchain-token/InterchainToken.sol';

error Invalid();

contract TestInterchainToken is InterchainToken {
    string public placeholder;

    constructor() InterchainToken(address(1)) {
        if (INITIALIZED_SLOT != bytes32(uint256(keccak256('interchain-token-initialized')) - 1)) revert Invalid();
    }

    function spendAllowance(address sender, address spender, uint256 amount) external {
        _spendAllowance(sender, spender, amount);
    }
}
