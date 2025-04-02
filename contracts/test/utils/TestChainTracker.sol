// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ChainTracker } from '../../utils/ChainTracker.sol';

contract TestChainTracker is ChainTracker {
    error Invalid();

    constructor() {
        if (CHAIN_TRACKER_SLOT != uint256(keccak256('ChainTracker.Slot')) - 1) revert Invalid();
    }

    /**
     * @notice Sets the trusted address for the specified chain.
     * @param chainName Chain name to be trusted.
     */
    function setTrustedChain(string memory chainName) external {
        _setTrustedChain(chainName);
    }

    /**
     * @notice Remove the trusted address of the chain.
     * @param chainName Chain name to remove the trusted address for.
     */
    function removeTrustedChain(string calldata chainName) external {
        _removeTrustedChain(chainName);
    }
}
