// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface IInterTokenExecutable {
    function exectuteWithInterToken(
        address tokenAddress,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        uint256 amount,
        bytes calldata data
    ) external;
}
