// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';
import { InterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/InterchainAddressTracker.sol';

import { IAddressTracker } from '../interfaces/IAddressTracker.sol';

contract AddressTracker is IAddressTracker, Ownable, InterchainAddressTracker {
    constructor(
        address owner_,
        string memory chainName_,
        string[] memory trustedChainNames,
        string[] memory trustedAddresses
    ) Ownable(owner_) InterchainAddressTracker(chainName_) {
        uint256 length = trustedChainNames.length;

        if (length != trustedAddresses.length) revert LengthMismatch();

        for (uint256 i; i < length; ++i) {
            _setTrustedAddress(trustedChainNames[i], trustedAddresses[i]);
        }
    }

    function setTrustedAddress(string memory chain, string memory address_) external onlyOwner {
        _setTrustedAddress(chain, address_);
    }

    function removeTrustedAddress(string memory chain) external onlyOwner {
        _removeTrustedAddress(chain);
    }
}
