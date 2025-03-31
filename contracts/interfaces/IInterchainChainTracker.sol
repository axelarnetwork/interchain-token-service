// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInterchainChainTracker {
    event TrustedChainSet(string chainName);
    event TrustedChainRemoved(string chainName);
    event ItsHubAddressSet(string hubAddress);

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

    /**
     * @notice Getter for whether a chain is trusted or not.
     * @dev Needs to be overwitten.
     * @return trusted whether the chain is trusted or not.
     */
    function isTrustedChain(string memory chain) external view returns (bool trusted);
}
