// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';

abstract contract InterchainTokenExecutable is IInterchainTokenExecutable {
    error NotService();

    address public immutable interchainTokenService;

    bytes32 internal constant EXECUTE_SUCCESS = keccak256('its-execute-success');

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
        address token,
        uint256 amount
    ) external virtual onlyService returns (bytes32) {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXECUTE_SUCCESS;
    }

    function _executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal virtual;
}
