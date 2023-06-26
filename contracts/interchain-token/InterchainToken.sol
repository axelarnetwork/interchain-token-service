// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ERC20 } from '../token-implementations/ERC20.sol';

/**
 * @title An example implementation of the IInterchainToken.
 * // TODO: probably should omit author due to company branding
 * @notice The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists
 * that can be used to create approvals, and that `allowance` is a mapping.
 * @dev You can skip the `tokenManagerRequiresApproval()` function altogether if you know what it should return for your token.
 */
// TODO: Actually let's move ERC20Permit inheritance to standardized token.
// We should inherit ERC20Permit for the standardized tokens directly, so this is flexible.
// We can define a virtual _approve method below that should be instantiated by the implementation.
abstract contract InterchainToken is IInterchainToken, ERC20 {
    // TODO: These don't need to be defined here
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager the TokenManager called to facilitate cross chain transfers.
     */
    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    /**
     * @notice Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers.
     * Usually, only mint/burn tokenManagers do not need approval.
     * @dev The return value depends on the implementation of ERC20.
     * In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the
     * TokenManager specifically to do it permissionlesly.
     * On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager
     * @return tokenManager the TokenManager called to facilitate cross chain transfers.
     */
    function tokenManagerRequiresApproval() public view virtual returns (bool);

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
        ITokenManager tokenManager = getTokenManager();
        /**
         * @dev if you know the value of `tokenManagerRequiresApproval()` you can just skip the if statement and just do nothing or _approve.
         */
        if (tokenManagerRequiresApproval()) {
            uint256 allowance_ = allowance[sender][address(tokenManager)];
            if (allowance_ != type(uint256).max) {
                if (allowance_ > type(uint256).max - amount) {
                    allowance_ = type(uint256).max - amount;
                }

                _approve(sender, address(tokenManager), allowance_ + amount);
            }
        }

        // Metadata semantics are defined by the token service and thus should be passed as-is.
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

        ITokenManager tokenManager = getTokenManager();
        if (tokenManagerRequiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }

        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }
}
