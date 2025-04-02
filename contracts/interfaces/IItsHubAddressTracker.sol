// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IItsHubAddressTracker Interface
 * @notice This interface allows getting the address and address hash of the ITS Hub.
 */
interface IItsHubAddressTracker {
    error InvalidHubAddress();

    /**
     * @notice Getter for the ITS Hub address.
     * @dev Needs to be overwritten.
     * @return hubAddress The ITS Hub address.
     */
    function itsHubAddress() external view returns (string memory hubAddress);

    /**
     * @notice Getter for the ITS HUB address hash.
     * @dev Needs to be overwitten.
     * @return hubAddressHash The ITS HUB address hash.
     */
    function itsHubAddressHash() external view returns (bytes32 hubAddressHash);
}
