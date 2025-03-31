// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { StringStorage } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/StringStorage.sol';

import { IInterchainChainTracker } from '../interfaces/IInterchainChainTracker.sol';

contract InterchainChainTracker is IInterchainChainTracker {
    /// @dev The ITS Hub Address Hash
    bytes32 public immutable itsHubAddressHash;

    /// @dev we need 3 32 byte slots to store the 65 bytes of the hub address.
    bytes32 private immutable itsHubAddressPrefix;
    bytes32 private immutable itsHubAddressMiddle;
    uint8 private immutable itsHubAddressSuffix;

    // uint256(keccak256('chain_tracker_slot')) - 1
    bytes32 internal constant CHAIN_TRACKER_SLOT = 0x6c51f1695661c243e1b0c3337f0f4c4f45116119470fb2cb0eb05fd857f16ac2;

    struct ChainTrackerStorage {
        mapping(string => bool) trustedChains;
    }

    constructor(string memory hubAddress) {
        if (bytes(hubAddress).length != 65) revert InvalidHubAddress();
        bytes32 itsHubAddressPrefix_;
        bytes32 itsHubAddressMiddle_;
        uint8 itsHubAddressSuffix_;
        assembly {
            itsHubAddressPrefix_ := mload(add(hubAddress, 32))
            itsHubAddressMiddle_ := mload(add(hubAddress, 64))
            itsHubAddressSuffix_ := mload(add(hubAddress, 65))
        }
        itsHubAddressPrefix = itsHubAddressPrefix_; 
        itsHubAddressMiddle = itsHubAddressMiddle_; 
        itsHubAddressSuffix = itsHubAddressSuffix_;
        itsHubAddressHash = keccak256(bytes(hubAddress));
    }

    function itsHubAddress() public view returns (string memory hubAddress) {
        bytes32 itsHubAddressPrefix_ = itsHubAddressPrefix;
        bytes32 itsHubAddressMiddle_ = itsHubAddressMiddle;
        uint8 itsHubAddressSuffix_ = itsHubAddressSuffix;
        hubAddress = new string(65);
        assembly {
            mstore(add(hubAddress, 32), itsHubAddressPrefix_)
            mstore(add(hubAddress, 65), itsHubAddressSuffix_)
            mstore(add(hubAddress, 64), itsHubAddressMiddle_)
        }
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
