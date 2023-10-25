// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStandardizedTokenRegistrar {
    error ZeroAddress();
    error NotDistributor();

    function chainName() external view returns (string memory);

    function chainNameHash() external view returns (bytes32);
}
