// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title TokenManagerProxy
 * @dev This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
 * inherits from FixedProxy from the gmp sdk repo
 */
interface ITokenManagerProxy {
    error ImplementationLookupFailed();
    error SetupFailed(bytes returnData);
    error NativeTokenNotAccepted();

    /**
     * @notice Returns implementation type of this token manager
     */
    function implementationType() external view returns (uint256);

    /**
     * @notice Returns the address of the current implementation.
     * @return impl The address of the current implementation
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns token ID of the token manager.
     */
    function tokenId() external view returns (bytes32);
}
