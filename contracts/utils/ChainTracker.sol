// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IChainTracker } from '../interfaces/IChainTracker.sol';

abstract contract ChainTracker is IChainTracker {
    // uint256(keccak256('ChainTracker.Slot')) - 1
    uint256 internal constant CHAIN_TRACKER_SLOT = 0xf310e759ad8669c4c98a2d6d3513430e0a108b0d6decc0cb580bedc5f185d123;

    struct ChainTrackerStorage {
        mapping(string => bool) trustedChains;
    }

    function _setTrustedChain(string memory chainName) internal {
        _chainTrackerStorage().trustedChains[chainName] = true;

        emit TrustedChainSet(chainName);
    }

    function _removeTrustedChain(string memory chainName) internal {
        _chainTrackerStorage().trustedChains[chainName] = false;

        emit TrustedChainRemoved(chainName);
    }

    function isTrustedChain(string memory chainName) public view returns (bool trusted) {
        trusted = _chainTrackerStorage().trustedChains[chainName];
    }

    /**
     * @notice Gets the specific storage location for preventing upgrade collisions
     * @return slot containing the storage struct
     */
    function _chainTrackerStorage() private pure returns (ChainTrackerStorage storage slot) {
        assembly {
            slot.slot := CHAIN_TRACKER_SLOT
        }
    }
}
