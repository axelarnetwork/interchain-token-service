// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestGatewayCaller {
    error DelegatecallFailed();

    function delegatecall(bytes memory) external pure returns (bool, bytes memory) {
        revert DelegatecallFailed();
    }
}
