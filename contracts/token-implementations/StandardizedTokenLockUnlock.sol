// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { StandardizedToken } from './StandardizedToken.sol';

contract StandardizedTokenLockUnlock is StandardizedToken {
    function tokenManagerRequiresApproval() public pure override returns (bool) {
        return true;
    }
}
