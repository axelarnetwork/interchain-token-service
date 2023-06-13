// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ERC20 } from '../utils/ERC20.sol';

abstract contract InterchainToken is IInterchainToken, ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;
        ITokenManager tokenManager = getTokenManager();
        if (tokenManager.requiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }
        if (metadata.length == 0) {
            tokenManager.sendSelf{ value: msg.value }(sender, destinationChain, recipient, amount);
        } else {
            tokenManager.callContractWithSelf{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
        }
    }

    // Send a token cross-chain from an account that has an approval to spend from `sender`'s balance
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != type(uint256).max) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        ITokenManager tokenManager = getTokenManager();
        if (tokenManager.requiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }
        if (metadata.length == 0) {
            tokenManager.sendSelf{ value: msg.value }(sender, destinationChain, recipient, amount);
        } else {
            tokenManager.callContractWithSelf{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
        }
    }
}
