// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenStandard } from '../interfaces/IInterchainTokenStandard.sol';
import { ITransmitInterchainToken } from '../interfaces/ITransmitInterchainToken.sol';

/**
 * @title An example implementation of the IInterchainTokenStandard.
 * @notice The is an abstract contract that needs to be extended with an ERC20 implementation. See `InterchainToken` for an example implementation.
 */
abstract contract InterchainTokenStandard is IInterchainTokenStandard {
    /**
     * @notice Getter for the tokenId used for this token.
     * @dev Needs to be overwritten.
     * @return tokenId_ The tokenId that this token is registerred under.
     */
    function interchainTokenId() public view virtual returns (bytes32 tokenId_);

    /**
     * @notice Getter for the interchain token service.
     * @dev Needs to be overwritten.
     * @return service The address of the interchain token service.
     */
    function interchainTokenService() public view virtual returns (address service);

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

        ITransmitInterchainToken(interchainTokenService()).transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            recipient,
            amount,
            metadata
        );
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
        _spendAllowance(sender, msg.sender, amount);

        _beforeInterchainTransfer(sender, destinationChain, recipient, amount, metadata);

        ITransmitInterchainToken(interchainTokenService()).transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            recipient,
            amount,
            metadata
        );
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

    /**
     * @notice A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.
     * @dev Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient.
     */
    function _spendAllowance(address sender, address spender, uint256 amount) internal virtual;
}
