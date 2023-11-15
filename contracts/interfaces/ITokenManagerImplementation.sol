// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerImplementation Interface
 * @notice Interface for returning the token manager implementation type.
 */
interface ITokenManagerImplementation {
    /**
     * @notice Returns the implementation address for a given token manager type.
     * @param tokenManagerType The type of token manager.
     * @return tokenManagerAddress_ The address of the token manager implementation.
     */
    function tokenManagerImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress_);
}
