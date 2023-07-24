// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ERC20 } from '../token-implementations/ERC20.sol';

/**
 * @title An example implementation of the IInterchainToken.
 * @notice The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists
 * that can be used to create approvals, and that `allowance` is a mapping.
 * @dev You can skip the `tokenManagerRequiresApproval()` function altogether if you know what it should return for your token.
 */
abstract contract InterchainToken is IInterchainToken, ERC20 {
    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager the TokenManager called to facilitate cross chain transfers.
     */
    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transfered.
     * @param metadata Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;
 
        _beforeInterchainTransfer(msg.sender, destinationChain, recipient, amount, metadata);

        ITokenManager tokenManager = getTokenManager();
        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
     * @param sender the sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain the string representation of the destination chain.
     * @param recipient the bytes representation of the address of the recipient.
     * @param amount the amount of token to be transfered.
     * @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
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
        
        _beforeInterchainTransfer(msg.sender, destinationChain, recipient, amount, metadata);

        ITokenManager tokenManager = getTokenManager();
        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /**
     * @notice A method to be overwritten that will be called before an interchain transfer. You can approve the tokenManager here if you need and want to, to allow users for a 1-call transfer in case of a lock-unlock token manager.
     * @param from the sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain the string representation of the destination chain.
     * @param destinationAddress the bytes representation of the address of the recipient.
     * @param amount the amount of token to be transfered.
     * @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
     */
    function _beforeInterchainTransfer(address from, string calldata destinationChain, bytes calldata destinationAddress, uint256 amount, bytes calldata metadata) internal virtual {}
}
