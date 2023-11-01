// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IImplementation Interface
 * @notice An interface for proxy contract implementations.
 */
interface IImplementation {
    error NotProxy();

    /**
     * @notice Called by the proxy to setup itself.
     * @dev This should be hidden by the proxy.
     * @param params the data to be used for the initialization.
     */
    function setup(bytes calldata params) external;
}
