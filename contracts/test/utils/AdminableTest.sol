// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Operatable } from '../../utils/Operatable.sol';

contract AdminableTest is Operatable {
    uint256 public nonce;

    constructor(address operator) {
        _setAdmin(operator);
    }

    function testAdminable() external onlyAdmin {
        nonce++;
    }
}
