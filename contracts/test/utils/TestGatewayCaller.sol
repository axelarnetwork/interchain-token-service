// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestGatewayCaller {
    function delegatecall(bytes memory) external pure returns (bool, bytes memory) {
        // solhint-disable-next-line reason-string
        revert();
    }
}