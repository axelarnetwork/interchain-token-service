// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerProxy Interface
 * @notice This interface is for a proxy for token manager contracts.
 */
interface ITokenManagerProxy {
    error ImplementationLookupFailed();
    error SetupFailed();
    error NativeTokenNotAccepted();

    /**
     * @notice Returns implementation type of this token manager.
     * @return uint256 The implementation type of this token manager.
     */
    function implementationType() external view returns (uint256);

    /**
     * @notice Returns the address of the current implementation.
     * @return address The address of the current implementation.
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns the token ID of the token manager.
     * @return bytes32 The token ID of the token manager.
     */
    function tokenId() external view returns (bytes32);
}
