// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenExpressExecutable } from '../executable/InterchainTokenExpressExecutable.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract TestInterchainExecutable is InterchainTokenExpressExecutable {
    event MessageReceived(
        bytes32 commandId,
        string sourceChain,
        bytes sourceAddress,
        address receiver,
        string message,
        bytes32 tokenId,
        uint256 amount
    );

    constructor(address interchainTokenService_) InterchainTokenExpressExecutable(interchainTokenService_) {}

    string public lastMessage;

    function _executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) internal override {
        (address receiver, string memory message) = abi.decode(data, (address, string));
        lastMessage = message;
        emit MessageReceived(commandId, sourceChain, sourceAddress, receiver, message, tokenId, amount);
        IERC20(token).transfer(receiver, amount);
    }
}
