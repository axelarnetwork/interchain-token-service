// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
