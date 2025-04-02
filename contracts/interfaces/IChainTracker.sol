// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IAddressTracker Interface
 * @notice This interface allows setting and removing a trusted address for a specific chain.
 * @dev Extends the IInterchainAddressTracker interface.
 */
interface IChainTracker {
    event TrustedChainSet(string chainName);
    event TrustedChainRemoved(string chainName);

    /**
     * @notice Getter for whether a chain is trusted or not.
     * @dev Needs to be overwitten.
     * @param chainName the name of the chain to query for.
     * @return trusted whether the chain is trusted or not.
     */
    function isTrustedChain(string memory chainName) external view returns (bool trusted);

    /**
     * @notice Sets the trusted address for the specified chain.
     * @param chainName Chain name to be trusted.
     */
    function setTrustedChain(string memory chainName) external;

    /**
     * @notice Remove the trusted address of the chain.
     * @param chainName Chain name to remove the trusted address for.
     */
    function removeTrustedChain(string calldata chainName) external;
}
