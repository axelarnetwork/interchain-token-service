// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainToken } from './IInterchainToken.sol';
import { IDistributable } from './IDistributable.sol';

/**
 * @title StandardizedToken
 * @notice This contract implements a standardized token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
interface IStandardizedToken is IInterchainToken, IDistributable {
    /**
     * @notice Returns the contract id, which a proxy can check to ensure no false implementation was used.
     */
    function contractId() external view returns (bytes32);

    /**
     * @notice Called by the proxy to setup itself.
     * @dev This should be hidden by the proxy.
     * @param params the data to be used for the initialization.
     */
    function setup(bytes calldata params) external;
}
