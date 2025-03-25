// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { StringStorage } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/StringStorage.sol';

import { IInterchainChainTracker } from '../interfaces/IInterchainChainTracker.sol';

contract InterchainChainTracker is IInterchainChainTracker {
    /// @dev This slot contains the ITS Hub Address
    /// keccak256('ItsHubAddress.Slot') - 1;
    bytes32 private constant ITS_HUB_ADDRESS_SLOT = 0xb51e9b8f3309a214d9b11b7b7f5fe09687a4af8a8345ed5a22a666349d2e6e9b;

    /// @dev This slot contains the ITS Hub Address Hash
    /// keccak256('ItsHubAddressHash.Slot') - 1;
    bytes32 private constant ITS_HUB_ADDRESS_HASH_SLOT = 0x0c1d88a695a4dde782068c5771da4ade87fc66ae5dbbcc7d911d5557bc586c21;

    bytes32 internal constant PREFIX_CHAIN_MAPPING = keccak256('interchain-chain-tracker-chain-mapping');

    /**
     * @dev Gets the key for the trusted address at a remote chain
     * @param chain Chain name of the remote chain
     * @return slot the slot to store the trusted address in
     */
    function _getTrustedChainSlot(string memory chain) internal pure returns (bytes32 slot) {
        slot = keccak256(abi.encode(PREFIX_CHAIN_MAPPING, chain));
    }

    function _setItsHubAddress(string memory hubAddress) internal {
        StringStorage.set(ITS_HUB_ADDRESS_SLOT, hubAddress);
        bytes32 hubAddressHash = keccak256(bytes(hubAddress));
        assembly {
            sstore(ITS_HUB_ADDRESS_HASH_SLOT, hubAddressHash)
        }
        emit ItsHubAddressSet(hubAddress);
    }

    function itsHubAddress() public view returns (string memory hubAddress) {
        hubAddress = StringStorage.get(ITS_HUB_ADDRESS_SLOT);
    }

    function itsHubAddressHash() public view returns (bytes32 hubAddressHash) {
        assembly {
            hubAddressHash := sload(ITS_HUB_ADDRESS_HASH_SLOT)
        }
    }

    function _setTrustedChain(string memory chain) internal {
        bytes32 slot = _getTrustedChainSlot(chain);
        assembly {
            sstore(slot, true)
        }
        emit TrustedChainSet(chain);
    }

    function _removeTrustedChain(string memory chain) internal {
        bytes32 slot = _getTrustedChainSlot(chain);
        assembly {
            sstore(slot, false)
        }
        emit TrustedChainRemoved(chain);
    }

    function isTrustedChain(string memory chain) public view returns (bool trusted) {
        bytes32 slot = _getTrustedChainSlot(chain);
        assembly {
            trusted := sload(slot)
        }
    }
}
