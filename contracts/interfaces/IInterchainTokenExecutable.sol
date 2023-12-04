// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenExecutable
 * @notice Contracts should implement this interface to accept calls from the InterchainTokenService.
 */
interface IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens are sent to this contract.
     * @dev Execution should revert unless the msg.sender is the InterchainTokenService
     * @param commandId The unique message id for the call.
     * @param sourceChain The name of the source chain.
     * @param sourceAddress The address that sent the contract call.
     * @param data The data to be processed.
     * @param tokenId The tokenId of the token manager managing the token.
     * @param token The address of the token.
     * @param amount The amount of tokens that were sent.
     * @return bytes32 Hash indicating success of the execution.
     */
    function executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external returns (bytes32);
}
