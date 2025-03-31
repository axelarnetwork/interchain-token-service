// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IAddressTracker Interface
 * @notice This interface allows setting and removing a trusted address for a specific chain.
 * @dev Extends the IInterchainAddressTracker interface.
 */
interface IItsHubAddressTracker {
    error InvalidHubAddress();

    /**
     * @notice Getter for the ITS HUB address.
     * @dev Needs to be overwitten.
     * @return hubAddress The ITS HUB address.
     */
    function itsHubAddress() external view returns (string memory hubAddress);

    /**
     * @notice Getter for the ITS HUB address hash.
     * @dev Needs to be overwitten.
     * @return hubAddressHash The ITS HUB address hash.
     */
    function itsHubAddressHash() external view returns (bytes32 hubAddressHash);
}
