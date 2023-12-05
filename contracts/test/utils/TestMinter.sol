// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Minter } from '../../utils/Minter.sol';

contract TestMinter is Minter {
    uint256 public nonce;

    constructor(address minter) {
        _addMinter(minter);
    }

    function testMinter() external onlyRole(uint8(Roles.MINTER)) {
        nonce++;
    }

    function minterRole() external pure returns (uint8) {
        return uint8(Roles.MINTER);
    }
}
