// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainAddressTracker.sol';

/**
 * @title IAddressTracker Interface
 * @notice This interface allows setting and removing a trusted address for a specific chain.
 * @dev Extends the IInterchainAddressTracker interface.
 */
interface IChainTracker is IInterchainAddressTracker {
    event TrustedChainSet(string chainName);
    event TrustedChainRemoved(string chainName);

    /**
     * @notice Getter for whether a chain is trusted or not.
     * @dev Needs to be overwitten.
     * @return trusted whether the chain is trusted or not.
     */
    function isTrustedChain(string memory chain) external view returns (bool trusted);

    /**
     * @notice Sets the trusted address for the specified chain.
     * @param chain Chain name to be trusted.
     */
    function setTrustedChain(string memory chain) external;

    /**
     * @notice Remove the trusted address of the chain.
     * @param chain Chain name to remove the trusted address for.
     */
    function removeTrustedChain(string calldata chain) external;
}
