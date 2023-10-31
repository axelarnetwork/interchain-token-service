// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Operatable } from '../../utils/Operatable.sol';

contract OperatorableTest is Operatable {
    uint256 public nonce;

    constructor(address operator) {
        _addOperator(operator);
    }

    function testOperatorable() external onlyRole(uint8(Roles.OPERATOR)) {
        nonce++;
    }

    function getOperatorRole() external pure returns (uint8) {
        return uint8(Roles.OPERATOR);
    }
}
