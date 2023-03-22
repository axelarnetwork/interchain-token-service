// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for proxy contracts
interface IImplementationLookup {
    function implementation() external view returns (address);
}
