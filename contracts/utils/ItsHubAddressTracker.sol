// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IItsHubAddressTracker } from '../interfaces/IItsHubAddressTracker.sol';

/**
 * @title ItsHubAddressTracker
 * @notice This contract is used to track the address of ITS Hub, and it uses immutable variables to save gas.
 */
abstract contract ItsHubAddressTracker is IItsHubAddressTracker {
    /// @dev The ITS Hub Address Hash
    bytes32 public immutable itsHubAddressHash;

    uint256 internal constant ADDRESS_LENGTH = 65;
    uint256 internal constant PREFIX_OFFSET = 32;
    uint256 internal constant MIDDLE_OFFSET = 64;
    uint256 internal constant SUFFIX_OFFSET = 65;

    /// @dev we need 3 32 byte slots to store the 65 bytes of the hub address.
    bytes32 private immutable itsHubAddressPrefix;
    bytes32 private immutable itsHubAddressMiddle;
    uint8 private immutable itsHubAddressSuffix;

    constructor(string memory hubAddress) {
        if (bytes(hubAddress).length != ADDRESS_LENGTH) revert InvalidHubAddress();

        bytes32 itsHubAddressPrefix_;
        bytes32 itsHubAddressMiddle_;
        uint8 itsHubAddressSuffix_;

        assembly ('memory-safe') {
            itsHubAddressPrefix_ := mload(add(hubAddress, PREFIX_OFFSET))
            itsHubAddressMiddle_ := mload(add(hubAddress, MIDDLE_OFFSET))
            itsHubAddressSuffix_ := mload(add(hubAddress, SUFFIX_OFFSET))
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
        hubAddress = new string(ADDRESS_LENGTH);

        assembly ('memory-safe') {
            mstore(add(hubAddress, PREFIX_OFFSET), itsHubAddressPrefix_)
            // This writes the 1-byte suffix to the 65th position, but also 31 other bytes into the middle. Hence, the middle is written after this to prevent it from being overwritten.
            mstore(add(hubAddress, SUFFIX_OFFSET), itsHubAddressSuffix_)
            mstore(add(hubAddress, MIDDLE_OFFSET), itsHubAddressMiddle_)
        }
    }
}
