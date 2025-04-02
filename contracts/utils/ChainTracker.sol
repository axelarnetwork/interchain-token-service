// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IChainTracker } from '../interfaces/IChainTracker.sol';

abstract contract ChainTracker is IChainTracker {
    // uint256(keccak256('chain_tracker_slot')) - 1
    bytes32 internal constant CHAIN_TRACKER_SLOT = 0x6c51f1695661c243e1b0c3337f0f4c4f45116119470fb2cb0eb05fd857f16ac2;

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
