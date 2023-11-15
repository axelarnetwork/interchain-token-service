// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenStandard } from '../interfaces/IInterchainTokenStandard.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';

import { ERC20 } from './ERC20.sol';

/**
 * @title An example implementation of the IInterchainTokenStandard.
 * @notice The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists
 * that can be used to create approvals, and that `allowance` is a mapping.
 */
abstract contract BaseInterchainToken is IInterchainTokenStandard, ERC20 {
    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwritten.
     * @return tokenManager_ The TokenManager called to facilitate interchain transfers.
     */
    function tokenManager() public view virtual returns (address tokenManager_);

    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed for an interchain contract call with transfer
     * as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;

        _beforeInterchainTransfer(msg.sender, destinationChain, recipient, amount, metadata);

        ITokenManager tokenManager_ = ITokenManager(tokenManager());
        tokenManager_.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param sender The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != UINT256_MAX) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        _beforeInterchainTransfer(sender, destinationChain, recipient, amount, metadata);

        ITokenManager tokenManager_ = ITokenManager(tokenManager());
        tokenManager_.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /**
     * @notice A method to be overwritten that will be called before an interchain transfer. One can approve the tokenManager here if needed,
     * to allow users for a 1-call transfer in case of a lock-unlock token manager.
     * @param from The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param destinationAddress The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer.
     */
    function _beforeInterchainTransfer(
        address from,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) internal virtual {}
}
