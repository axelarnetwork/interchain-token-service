// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Distributable } from '../../utils/Distributable.sol';

contract TestDistributable is Distributable {
    uint256 public nonce;

    constructor(address minter) {
        _addMinter(minter);
    }

    function testDistributable() external onlyRole(uint8(Roles.MINTER)) {
        nonce++;
    }

    function minterRole() external pure returns (uint8) {
        return uint8(Roles.MINTER);
    }
}
