// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';

abstract contract InterchainTokenExecutable is IInterchainTokenExecutable {
    error NotService();

    address public immutable interchainTokenService;

    constructor(address interchainTokenService_) {
        interchainTokenService = interchainTokenService_;
    }

    modifier onlyService() {
        if (msg.sender != interchainTokenService) revert NotService();
        _;
    }

    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external onlyService {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
    }

    function _executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) internal virtual;
}
