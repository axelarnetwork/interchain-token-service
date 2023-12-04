// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from './IInterchainTokenExecutable.sol';

/**
 * @title IInterchainTokenExpressExecutable
 * @notice Contracts should implement this interface to accept express calls from the InterchainTokenService.
 */
interface IInterchainTokenExpressExecutable is IInterchainTokenExecutable {
    /**
     * @notice Executes express logic in the context of an interchain token transfer.
     * @dev Only callable by the interchain token service.
     * @param commandId The unique message id for the call.
     * @param sourceChain The source chain of the token transfer.
     * @param sourceAddress The source address of the token transfer.
     * @param data The data associated with the token transfer.
     * @param tokenId The token ID.
     * @param token The token address.
     * @param amount The amount of tokens to be transferred.
     * @return bytes32 Hash indicating success of the express execution.
     */
    function expressExecuteWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external returns (bytes32);
}
