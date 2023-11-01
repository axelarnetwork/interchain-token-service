// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from './IInterchainTokenExecutable.sol';

/**
 * @title IInterchainTokenExpressExecutable Interface
 * @notice This interface contains functions for accepting express calls from the InterchainTokenService.
 */
interface IInterchainTokenExpressExecutable is IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens are sent to this contract.
     * @dev Execution should revert unless the msg.sender is the InterchainTokenService.
     * @param sourceChain The name of the source chain.
     * @param sourceAddress The address that sent the contract call.
     * @param data The data to be processed.
     * @param tokenId The token id of the token manager managing the token.
     * @param token The address of the token.
     * @param amount The amount of token that was sent.
     */
    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external;
}
