// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenLinkerType } from '../interfaces/ITokenLinkerType.sol';

interface ITokenLinkerProxy is ITokenLinkerType {
    error ImplementationLookupFailed();
    error SetupFailed();

    function implementationType() external returns (TokenLinkerType);

    function implementation() external returns (address);
}
