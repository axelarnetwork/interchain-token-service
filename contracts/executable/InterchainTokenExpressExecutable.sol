// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { InterchainTokenExecutable } from './InterchainTokenExecutable.sol';

abstract contract InterchainTokenExpressExecutable is IInterchainTokenExpressExecutable, InterchainTokenExecutable {
    bytes32 internal constant EXPRESS_EXECUTE_SUCCESS = keccak256('its-express-execute-success');

    constructor(address interchainTokenService_) InterchainTokenExecutable(interchainTokenService_) {}

    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external virtual onlyService returns (bytes32) {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXPRESS_EXECUTE_SUCCESS;
    }
}
