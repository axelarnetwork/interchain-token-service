// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IImplementation } from '../interfaces/IImplementation.sol';

abstract contract Implementation is IImplementation {
    address private immutable implementationAddress;

    constructor() {
        implementationAddress = address(this);
    }

    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    // make sure that this function has the OnlyProxy modifier when implemented
    function setup(bytes calldata params) external virtual;
}
