// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BytecodeServer {
    constructor(bytes memory bytecode) {
        uint256 len = bytecode.length;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            return(add(bytecode, 32), len)
        }
    }
}
