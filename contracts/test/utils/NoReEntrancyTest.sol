// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { NoReEntrancy } from '../../utils/NoReEntrancy.sol';

contract NoReEntrancyTest is NoReEntrancy {
    uint256 public value;

    function testFunction() external noReEntrancy {
        value = 1;
        this.callback();
        value = 2;
    }

    function callback() external noReEntrancy {}
}
