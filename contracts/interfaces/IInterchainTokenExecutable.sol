// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenExecutable
 * @notice Implement this to accept calls from the InterchainTokenService.
 */
interface IInterchainTokenExecutable {
    /**
     * @notice This will be called after the tokens arrive to this contract
     * @dev You are revert unless the msg.sender is the InterchainTokenService
     * @param sourceChain the name of the source chain
     * @param sourceAddress the address that sent the contract call
     * @param data the data to be proccessed
     * @param tokenId the tokenId of the token manager managing the token. You can access it's address by querrying the service
     * @param amount the amount of token that was sent
     */
    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;
}
