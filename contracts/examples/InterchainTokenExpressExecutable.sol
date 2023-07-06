// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { InterchainTokenExecutable } from './InterchainTokenExecutable.sol';

abstract contract InterchainTokenExpressExecutable is IInterchainTokenExpressExecutable, InterchainTokenExecutable {
    constructor(address interchainTokenService_) InterchainTokenExecutable(interchainTokenService_) {}

    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external onlyService {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
    }
}
