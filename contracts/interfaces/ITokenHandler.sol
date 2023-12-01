// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerType } from './ITokenManagerType.sol';

/**
 * @title ITokenManager Interface
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
interface ITokenHandler is ITokenManagerType {
    error UnsupportedTokenManagerType(uint256 tokenManagerType);

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param destinationAddress The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address destinationAddress,
        uint256 amount
    ) external payable returns (uint256);

    /**
     * @notice This function takes token to from a specified address.
     * @dev Can only be called by the service.
     * @param sourceAddress The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address sourceAddress,
        uint256 amount
    ) external payable returns (uint256);
}
