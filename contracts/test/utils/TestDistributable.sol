// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Distributable } from '../../utils/Distributable.sol';

contract TestDistributable is Distributable {
    uint256 public nonce;

    constructor(address distributor) {
        _addDistributor(distributor);
    }

    function testDistributable() external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        nonce++;
    }

    function distributorRole() external pure returns (uint8) {
        return uint8(Roles.DISTRIBUTOR);
    }
}
