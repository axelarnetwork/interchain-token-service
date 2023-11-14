// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { InterchainTokenExecutable } from '../executable/InterchainTokenExecutable.sol';
import { InterchainTokenExpressExecutable } from '../executable/InterchainTokenExpressExecutable.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract InvalidInterchainExecutableTest is InterchainTokenExpressExecutable {
    bytes32 internal constant EXECUTE_FAILURE = keccak256('its-express-execute-failure');
    bytes32 internal constant EXPRESS_EXECUTE_FAILURE = keccak256('its-express-execute-failure');

    event MessageReceived(string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount);

    constructor(address interchainTokenService_) InterchainTokenExpressExecutable(interchainTokenService_) {}

    string public lastMessage;

    function executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external override(IInterchainTokenExecutable, InterchainTokenExecutable) onlyService returns (bytes32) {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXECUTE_FAILURE;
    }

    function expressExecuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external override onlyService returns (bytes32) {
        _executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXPRESS_EXECUTE_FAILURE;
    }

    function _executeWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal override {
        (address receiver, string memory message) = abi.decode(data, (address, string));
        lastMessage = message;
        emit MessageReceived(sourceChain, sourceAddress, receiver, message, tokenId, amount);
        IERC20(token).transfer(receiver, amount);
    }
}
