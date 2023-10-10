// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenExecutable
 * @notice Implement this to accept calls from the InterchainTokenService.
 */
interface IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens arrive to this contract
     * @dev Executable should revert unless the msg.sender is the InterchainTokenService
     * @param sourceChain the name of the source chain
     * @param sourceAddress the address that sent the contract call
     * @param data the data to be processed
     * @param tokenId the tokenId of the token manager managing the token.
     * @param token the address of the token.
     * @param amount the amount of token that was sent
     */
    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external;
}
