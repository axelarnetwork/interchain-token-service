// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IInterchainTokenExecutable } from './IInterchainTokenExecutable.sol';

// All interfaces should be documented, especially since external devs look at interfaces first
// General interface for upgradable contracts
interface IInterchainTokenExpressExecutable is IInterchainTokenExecutable {
    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;
}
