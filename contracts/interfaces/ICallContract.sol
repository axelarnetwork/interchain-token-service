// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC20MintableBurnable Interface
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICallContract {
    enum MetadataVersion {
        CONTRACT_CALL,
        EXPRESS_CALL
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called.
     * @param destinationAddress The target address on the destination chain.
     * @param payload The data payload for the transaction.
     * @param metadataVersion The metadata version
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes memory payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Calls a contract on a specific destination chain with the given payload and gateway token
     * @param destinationChain The target chain where the contract will be called.
     * @param destinationAddress The target address on the destination chain.
     * @param payload The data payload for the transaction.
     * @param symbol The gateway symbol of the token.
     * @param amount The amount of token transfered.
     * @param metadataVersion The metadata version
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes memory payload,
        string memory symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;
}
