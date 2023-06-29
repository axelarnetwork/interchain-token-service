// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Adminable } from '../../utils/Adminable.sol';

contract AdminableTest is Adminable {
    uint256 public nonce;

    constructor(address admin) {
        _setAdmin(admin);
    }

    function testAdminable() external onlyAdmin {
        nonce++;
    }
}
