// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library AddressBytesUtils {
    function toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    function toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);
        assembly {
            mstore(add(bytesAddress, 20), addr)
        }
    }
}
