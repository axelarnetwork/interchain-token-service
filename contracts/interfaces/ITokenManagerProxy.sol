// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManagerType } from './ITokenManagerType.sol';

interface ITokenManagerProxy is ITokenManagerType {
    error ImplementationLookupFailed();
    error SetupFailed();

    function implementationType() external returns (TokenManagerType);

    function implementation() external returns (address);
}
