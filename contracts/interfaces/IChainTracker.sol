// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainAddressTracker.sol';

import { IInterchainChainTracker } from './IInterchainChainTracker.sol';

/**
 * @title IAddressTracker Interface
 * @notice This interface allows setting and removing a trusted address for a specific chain.
 * @dev Extends the IInterchainAddressTracker interface.
 */
interface IChainTracker is IInterchainAddressTracker, IInterchainChainTracker {
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
