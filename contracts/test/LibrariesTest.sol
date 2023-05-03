// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';

contract LibrariesTest {
    using AddressBytesUtils for address;

    function addressToBytes(address addr) external pure returns (bytes memory bytesAddress) {
        bytesAddress = addr.toBytes();
    }
}