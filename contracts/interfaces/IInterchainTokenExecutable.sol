// SPDX-License-Identifier: MIT

// can we add ^ for all versions. We're enforcing version via hardhat config
pragma solidity ^0.8.9;

// All interfaces should be documented, especially since external devs look at interfaces first
// General interface for upgradable contracts
interface IInterchainTokenExecutable {
    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;
}
