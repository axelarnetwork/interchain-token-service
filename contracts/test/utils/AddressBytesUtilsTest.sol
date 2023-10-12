// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytesUtils } from '../../libraries/AddressBytesUtils.sol';

contract AddressBytesUtilsTest {
    using AddressBytesUtils for address;
    using AddressBytesUtils for bytes;

    function toAddress(bytes memory bytesAddress) external pure returns (address addr) {
        return bytesAddress.toAddress();
    }

    function toBytes(address addr) external pure returns (bytes memory bytesAddress) {
        return addr.toBytes();
    }
}
