// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
// You can have your own implementation of ERC20, but unfortunatelly we had to include an implementations to have access to the _approve method as well as the allowance mapping
import { ERC20Permit } from '../utils/ERC20Permit.sol';

/// @title An example implementation of the IInterchainTokenInterface.
/// @notice The implementation ERC20 can be done in any way, however this example assumes that an _approve internal function exists that can be used to create approvals, and that `allowance` is a mapping.
/// @dev You can skip the `tokenManagerRequiresApproval()` function alltogether if you know what it should return for your token.
abstract contract InterchainToken is IInterchainToken, ERC20Permit {
    string public name;
    string public symbol;
    uint8 public decimals;

    /// @notice Getter for the tokenManager used for this token.
    /// @dev Needs to be overwitten.
    /// @return tokenManager the TokenManager called to facilitate cross chain transfers.
    function getTokenManager() public view virtual returns (ITokenManager tokenManager);

    /// @notice Getter function specifiying if the tokenManager requires approval to facilitate cross-chain transfers.
    /// Usually, only mint/burn tokenManagers do not need approval.
    /// @dev The return value depends on the implementation of ERC20.
    /// In case of lock/unlock and liquidity pool TokenManagers it is possible to implement transferFrom to allow the TokenManager specifically to do it permissionlesly.
    /// On the other hand you can implement burn in a way that requires approval for a mint/burn TokenManager
    /// @return tokenManager the TokenManager called to facilitate cross chain transfers.
    function tokenManagerRequiresApproval() public view virtual returns (bool);

    /// @notice Implementation of the interchainTransfer method
    /// @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
    /// A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
    /// @param destinationChain the string representation of the destination chain.
    /// @param recipient the bytes representation of the address of the recipient.
    /// @param amount the amount of token to be transfered.
    /// @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;
        ITokenManager tokenManager = getTokenManager();
        // TODO: this is not needed for mint/burn tokens, so we could split it out
        /// @dev if you know the value of `tokenManagerRequiresApproval()` you can just skip the if statement and just do nothing or _approve.
        if (tokenManagerRequiresApproval()) {
            _approve(sender, address(tokenManager), allowance[sender][address(tokenManager)] + amount);
        }

        // TODO: Don't think this should be resolved here. The token contract is fixed, whereas metadata interpretation
        // can evolve in the future. Metadata should be passed as-is to the token service.
        // Metadata should also be versioned:
        // - if metadata is empty, interpret it as a simple transfer
        // - if metadata has a bytes4/bytes32(0) prefix, then it's transfer with data
        // - other versions can add more features in the future, without breaking semantics
        tokenManager.transmitInterchainTransfer{ value: msg.value }(sender, destinationChain, recipient, amount, metadata);
    }

    /// @notice Implementation of the interchainTransferFrom method
    /// @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
    /// A different implementation could have `metadata` that tells this function which function to use or that it is used for anything else as well.
    /// @param sender the sender of the tokens. They need to have approved `msg.sender` before this is called.
    /// @param destinationChain the string representation of the destination chain.
    /// @param recipient the bytes representation of the address of the recipient.
    /// @param amount the amount of token to be transfered.
    /// @param metadata either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
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
