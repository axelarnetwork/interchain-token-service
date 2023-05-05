// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ERC20BurnableMintable } from '../utils/ERC20BurnableMintable.sol';

contract InterchainToken is IInterchainToken, ERC20BurnableMintable {
    IInterchainTokenService public immutable interchainTokenService;

    constructor(address interchainTokenServiceAddress) {
        interchainTokenService = IInterchainTokenService(interchainTokenServiceAddress);
    }

    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        if (metadata.length == 0) {
            _interchainTransfer(msg.sender, destinationChain, recipient, amount);
        } else {
            _interchainTransferWithData(msg.sender, destinationChain, recipient, amount, metadata);
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

        if (metadata.length == 0) {
            _interchainTransfer(sender, destinationChain, recipient, amount);
        } else {
            _interchainTransferWithData(sender, destinationChain, recipient, amount, metadata);
        }
    }

    function _interchainTransfer(address sender, string calldata destinationChain, bytes calldata recipient, uint256 amount) internal {
        uint256 currentAllowance = allowance[sender][address(interchainTokenService)];

        if (currentAllowance != type(uint256).max) {
            _approve(sender, address(interchainTokenService), currentAllowance + amount);
        }

        interchainTokenService.sendSelf{ value: msg.value }(sender, destinationChain, recipient, amount);
    }

    function _interchainTransferWithData(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata data
    ) internal {
        uint256 currentAllowance = allowance[sender][address(interchainTokenService)];

        if (currentAllowance != type(uint256).max) {
            _approve(sender, address(interchainTokenService), currentAllowance + amount);
        }

        interchainTokenService.callContractWithSelf{ value: msg.value }(sender, destinationChain, recipient, amount, data);
    }
}
