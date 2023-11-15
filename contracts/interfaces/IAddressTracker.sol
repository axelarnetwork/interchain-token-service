// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainAddressTracker.sol';

/**
 * @title IAddressTracker Interface
 * @notice This interface allows setting and removing a trusted address for a specific chain.
 * @dev Extends the IInterchainAddressTracker interface.
 */
interface IAddressTracker is IInterchainAddressTracker {
    /**
     * @notice Sets the trusted address for the specified chain.
     * @param chain Chain name to be trusted.
     * @param address_ Trusted address to be added for the chain.
     */
    function setTrustedAddress(string memory chain, string memory address_) external;

    /**
     * @notice Remove the trusted address of the chain.
     * @param chain Chain name to remove the trusted address for.
     */
    function removeTrustedAddress(string calldata chain) external;
}
