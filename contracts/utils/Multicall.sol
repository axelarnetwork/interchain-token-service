// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IMulticall } from '../interfaces/IMulticall.sol';

contract Multicall is IMulticall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                if (result.length < 68) revert(string(result));
            }

            results[i] = result;
        }
    }
}
