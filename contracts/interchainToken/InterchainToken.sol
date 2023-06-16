// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
// You can have your own implementation of ERC20, but unfortunatelly we had to include an implementations to have access to the _approve method as well as the allowance mapping
import { ERC20Permit } from '../utils/ERC20Permit.sol';

/**
 * @title InterchainToken
 * @dev Contract that implements the IInterchainToken interface and allows for interchain token transfers.
 * This contract also inherits ERC20Permit to allow for approvals using off-chain signatures.
 * This contract is abstract and is intended to be inherited by another contract.
 */
abstract contract InterchainToken is IInterchainToken, ERC20Permit {
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @dev A function that returns the token manager for this InterchainToken.
     * Must be overridden in the inheriting contract.
     * @return tokenManager The token manager contract
     */
    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    /**
     * @dev A function that checks if the token manager requires an approval.
     * Must be overridden in the inheriting contract.
     * @return Boolean representing if the token manager requires approval
     */
    function tokenManagerRequiresApproval() public view virtual returns (bool);

    /**
     * @dev A function that handles interchain transfers for this token
     * @param destinationChain The chain to which the tokens will be sent
     * @param recipient The recipient address of the tokens represented in bytes
     * @param amount The amount of tokens to send
     * @param metadata Any additional data to include with the transfer
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;
        ITokenManager tokenManager = getTokenManager();
        if (tokenManagerRequiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }
        if (metadata.length == 0) {
            tokenManager.sendSelf{ value: msg.value }(sender, destinationChain, recipient, amount);
        } else {
            tokenManager.callContractWithSelf{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
        }
    }

    /**
     * @dev A function to send a token cross-chain from an account that has an approval
     * to spend from `sender`'s balance
     * @param sender The account to send the tokens from
     * @param destinationChain The chain to which the tokens will be sent
     * @param recipient The recipient address of the tokens represented in bytes
     * @param amount The amount of tokens to send
     * @param metadata Any additional data to include with the transfer
     */
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
        if (tokenManagerRequiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }
        if (metadata.length == 0) {
            tokenManager.sendSelf{ value: msg.value }(sender, destinationChain, recipient, amount);
        } else {
            tokenManager.callContractWithSelf{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
        }
    }
}
