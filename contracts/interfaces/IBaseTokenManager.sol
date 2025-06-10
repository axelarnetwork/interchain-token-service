// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBaseTokenManager
 * @notice This contract is defines the base token manager interface implemented by all token managers.
 */
interface IBaseTokenManager {
    /**
     * @notice A function that returns the token id.
     */
    function interchainTokenId() external view returns (bytes32);

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the token address from the init params.
     */
    function getTokenAddressFromParams(bytes calldata params) external pure returns (address);

    /**
     * @notice A function that should return the native interchain token deployment params.
     */
    function getTokenDeployInfoFromParams(
        bytes calldata params
    ) external pure returns (bytes memory, string memory, string memory, uint8, uint256);
}
