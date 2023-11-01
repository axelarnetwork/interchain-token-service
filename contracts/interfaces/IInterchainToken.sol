// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IInterchainToken {
    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager_ The TokenManager called to facilitate cross chain transfers.
     */
    function tokenManager() external view returns (ITokenManager tokenManager_);

    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, to just facilitate an interchain transfer, or the data can be passed for an interchain contract call with transfer as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param sender The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, to just facilitate a cross-chain transfer, or the data to be passed to a cross-chain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}
