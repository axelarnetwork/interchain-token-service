// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IGatewayCaller interface
 * @dev Interface for the GatewayCaller contract
 */
interface IGatewayCaller {
    /**
     * @dev Enum representing different metadata versions
     */
    enum MetadataVersion {
        CONTRACT_CALL,
        EXPRESS_CALL
    }

    /**
     * @dev Error thrown when an invalid metadata version is provided
     */
    error InvalidMetadataVersion(uint32 metadataVersion);

    /**
     * @dev Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called
     * @param destinationAddress The address of the contract to be called on the destination chain
     * @param payload The data payload for the transaction
     * @param metadataVersion The version of metadata to be used
     * @param gasValue The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;

    /**
     * @dev Calls a contract on a specific destination chain with the given payload and token
     * @param destinationChain The target chain where the contract will be called
     * @param destinationAddress The address of the contract to be called on the destination chain
     * @param payload The data payload for the transaction
     * @param symbol The symbol of the token to be sent
     * @param amount The amount of tokens to be sent
     * @param metadataVersion The version of metadata to be used
     * @param gasValue The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue.
     */
    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;
}
