// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';

import { IBaseTokenManager } from './IBaseTokenManager.sol';
import { IOperatable } from './IOperatable.sol';
import { IFlowLimit } from './IFlowLimit.sol';

/**
 * @title ITokenManager Interface
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
interface ITokenManager is IBaseTokenManager, IOperatable, IFlowLimit, IImplementation {
    error TokenLinkerZeroAddress();
    error NotService(address caller);
    error TakeTokenFailed();
    error GiveTokenFailed();
    error NotToken(address caller);
    error ZeroAddress();
    error AlreadyFlowLimiter(address flowLimiter);
    error NotFlowLimiter(address flowLimiter);
    error NotSupported();

    /**
     * @notice Calls the service to initiate an interchain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The address of the user to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param metadata Any additional data to be sent with the transfer.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Calls the service to initiate an interchain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The address on the destination chain to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param data The data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    /**
     * @notice Calls the service to initiate an interchain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender The address of the sender paying for the interchain transfer.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress  The address on the destination chain to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param metadata Any additional data to be sent with the transfer.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param destinationAddress The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function takes token to from a specified address.
     * @dev Can only be called by the service.
     * @param sourceAddress The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(address sourceAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function adds a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of the new flow limiter.
     */
    function addFlowLimiter(address flowLimiter) external;

    /**
     * @notice This function removes a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of an existing flow limiter.
     */
    function removeFlowLimiter(address flowLimiter) external;

    /**
     * @notice Query if an address is a flow limiter.
     * @param addr The address to query for.
     * @return bool Boolean value representing whether or not the address is a flow limiter.
     */
    function isFlowLimiter(address addr) external view returns (bool);

    /**
     * @notice This function sets the flow limit for this TokenManager.
     * @dev Can only be called by the flow limiters.
     * @param flowLimit_ The maximum difference between the tokens flowing in and/or out at any given interval of time (6h).
     */
    function setFlowLimit(uint256 flowLimit_) external;
}
