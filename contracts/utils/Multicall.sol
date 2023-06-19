// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IMulticall } from '../interfaces/IMulticall.sol';

contract Multicall is IMulticall {
    error MulticallFailed(bytes err);

    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // TODO: Wrap this in a typed MulticallFailed error
                revert MulticallFailed(result);
            }

            results[i] = result;
        }
    }
}
