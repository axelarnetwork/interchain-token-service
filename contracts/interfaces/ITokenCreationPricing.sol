// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenCreationPricing
 * @notice Interface for managing token creation pricing functionality
 */
interface ITokenCreationPricing {
    /**
     * @notice Error thrown when an invalid price is provided
     */
    error InvalidTokenCreationPrice();

    /**
     * @notice Error thrown when an invalid WHBAR address is provided
     */
    error InvalidWhbarAddress();

    /**
     * @notice Returns the token creation price in tinycents
     * @return price The token creation price in tinycents
     */
    function tokenCreationPrice() external view returns (uint256 price);

    /**
     * @notice Returns the WHBAR contract address
     * @return whbarAddress The WHBAR contract address
     */
    function whbarAddress() external view returns (address whbarAddress);
}
