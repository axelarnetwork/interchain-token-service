// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestGatewayCaller {    
    function delegatecall(bytes memory) external returns (bool, bytes memory) {
        return (false, '');
    }
}