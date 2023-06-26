// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { StandardizedToken } from './StandardizedToken.sol';

contract StandardizedTokenMintBurn is StandardizedToken {
    function tokenManagerRequiresApproval() public pure override returns (bool) {
        return false;
    }
}
