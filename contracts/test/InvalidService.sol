// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract InvalidService {
    function tokenManagerImplementation(uint256) external pure returns (address) {
        return address(0);
    }
}
