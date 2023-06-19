// SPDX-License-Identifier: MIT

// can we add ^ for all versions. We're enforcing version via hardhat config
pragma solidity ^0.8.9;

// TODO: Add a base implementation that requires caller of execute to be the token service
// All interfaces should be documented, especially since external devs look at interfaces first
// General interface for upgradable contracts
interface IInterchainTokenExecutable {
    // TODO: typo
    function executeWithInterchainToken(
        string calldata sourceChain,
        // TODO: If we really want to keep the interface similar, we can use string here but cast it to bytes internally
        bytes calldata sourceAddress,
        bytes calldata data,
        // TODO: similarly this could be a string but not really contain the symbol
        bytes32 tokenId,
        uint256 amount
    ) external;
}
