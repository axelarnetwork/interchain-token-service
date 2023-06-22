// SPDX-License-Identifier: MIT

// TODO: can we add ^ for all versions and use ^0.8.0 instead? We're enforcing version via hardhat config, but don't wanna restrict for other people
pragma solidity ^0.8.9;

// TODO: All interfaces should be documented, especially since external devs look at interfaces first. Implementations can mention some implementation details if needed instead.
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
