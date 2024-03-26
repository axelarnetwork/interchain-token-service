// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Fixed } from '../../utils/Create3Fixed.sol';

contract TestCreate3Fixed is Create3Fixed {
    event Deployed(address addr);

    function deploy(bytes memory code, bytes32 salt) public payable returns (address addr) {
        addr = _create3(code, salt);

        emit Deployed(addr);
    }

    function deployedAddress(bytes32 salt) public view returns (address addr) {
        addr = _create3Address(salt);
    }
}
