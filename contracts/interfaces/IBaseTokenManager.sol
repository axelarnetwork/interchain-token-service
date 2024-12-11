// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBaseTokenManager
 * @notice This contract is defines the base token manager interface implemented by all token managers.
 */
interface IBaseTokenManager {
    /**
     * @notice A function that returns the token id.
     * @dev This is stored in the proxy and should not be called in the implementation, but it is included here so that the interface properly tells us what functions exist.
     */
    function interchainTokenId() external view returns (bytes32);

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @dev This is stored in the proxy and should not be called in the implementation, but it is included here so that the interface properly tells us what functions exist.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the token address from the init params.
     */
    function getTokenAddressFromParams(bytes calldata params) external pure returns (address);
}
