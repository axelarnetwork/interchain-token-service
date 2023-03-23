// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenDeployer {
    function deployToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        bytes32 salt
    ) external payable returns (address tokenAddress);
}
