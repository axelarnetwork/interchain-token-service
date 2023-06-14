// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStandardizedTokenProxy {
    error WrongImplementation();

    function contractId() external view returns (bytes32);
}
