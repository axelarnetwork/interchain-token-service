// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenDeployer {
    function deployToken(bytes calldata args, bytes32 salt) external payable returns (address tokenAddress);
}
