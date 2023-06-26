// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title AddressBytesUtils
 * @dev This library provides utility functions to convert between `address` and `bytes`.
 */
library AddressBytesUtils {
    error InvalidBytesLength(bytes bytesAddress);

    /**
     * @dev Converts a bytes address to an address type.
     * @param bytesAddress The bytes representation of an address
     * @return addr The converted address
     */
    function toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        if (bytesAddress.length != 20) revert InvalidBytesLength(bytesAddress);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    /**
     * @dev Converts an address to bytes.
     * @param addr The address to be converted
     * @return bytesAddress The bytes representation of the address
     */
    function toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(bytesAddress, 20), addr)
            mstore(bytesAddress, 20)
        }
    }
}
