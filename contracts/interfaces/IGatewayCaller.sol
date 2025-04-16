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
        CONTRACT_CALL
    }

    /**
     * @dev Error thrown when an invalid metadata version is provided
     */
    error InvalidMetadataVersion(uint32 metadataVersion);

    /**
     * @notice Call the Axelar gateway to send a payload to a destination contract on a specific destination chain
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
}
