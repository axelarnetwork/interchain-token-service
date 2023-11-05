// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IOwnable.sol';
import { IInterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainAddressTracker.sol';

interface IAddressTracker is IInterchainAddressTracker {
    /**
     * @dev Sets the trusted address for the specified chain
     * @param chain Chain name to be trusted
     * @param address_ Trusted address to be added for the chain
     */
    function setTrustedAddress(string memory chain, string memory address_) external;

    /**
     * @dev Remove the trusted address of the chain.
     * @param chain Chain name that should be made untrusted
     */
    function removeTrustedAddress(string calldata chain) external;
}
