// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManagerType } from './ITokenManagerType.sol';

interface ITokenManagerProxy is ITokenManagerType {
    error ImplementationLookupFailed();
    error SetupFailed();

    function implementationType() external view returns (TokenManagerType);

    function implementation() external view returns (address);

    function tokenId() external view returns (bytes32);
}
