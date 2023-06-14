// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from './IInterchainToken.sol';

interface IStandardizedToken is IInterchainToken {
    function contractId() external view returns (bytes32);

    function setup(bytes calldata params) external;
}
