// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Implementation } from '../../utils/Implementation.sol';

contract ImplementationTest is Implementation {
    uint256 public val;

    function setup(bytes calldata params) external override onlyProxy {
        val = abi.decode(params, (uint256));
    }
}
