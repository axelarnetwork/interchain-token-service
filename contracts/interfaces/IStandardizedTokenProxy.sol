// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStandardizedTokenProxy {
    error WrongImplementation();

    function contractId() external view returns (bytes32);
}
