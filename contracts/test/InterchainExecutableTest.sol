// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract InterchainExecutableTest is IInterchainTokenExecutable {
    event MessageReceived(string sourceChain, bytes sourceAddress, address receiver, string message, bytes32 tokenId, uint256 amount);

    string public lastMessage;

    function exectuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external {
        (address receiver, string memory message) = abi.decode(data, (address, string));
        lastMessage = message;
        address tokenAddress = IInterchainTokenService(msg.sender).getTokenAddress(tokenId);
        IERC20(tokenAddress).transfer(receiver, amount);
        emit MessageReceived(sourceChain, sourceAddress, receiver, message, tokenId, amount);
    }
}
