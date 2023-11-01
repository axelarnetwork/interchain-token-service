// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerType } from './ITokenManagerType.sol';
import { IOperatable } from './IOperatable.sol';
import { IFlowLimit } from './IFlowLimit.sol';
import { IImplementation } from './IImplementation.sol';

/**
 * @title ITokenManager Interface
 * @notice This interface is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
interface ITokenManager is ITokenManagerType, IOperatable, IFlowLimit, IImplementation {
    error TokenLinkerZeroAddress();
    error NotService(address caller);
    error TakeTokenFailed();
    error GiveTokenFailed();
    error NotToken(address caller);
    error ZeroAddress();
    error AlreadyFlowLimiter(address flowLimiter);
    error NotFlowLimiter(address flowLimiter);

    /**
     * @notice A function that returns the token id.
     * @return bytes32 The token id.
     */
    function tokenId() external view returns (bytes32);

    /**
     * @notice A function that should return the address of the token.
     * @dev Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the implementation type of the token manager.
     * @return uint256 The implementation type of the token manager.
     */
    function implementationType() external pure returns (uint256);

    /**
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.
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
     * @notice Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
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
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender The address of the sender paying for the cross chain transfer.
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
     * @notice This function sets the flow limit for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimit The maximum difference between the tokens flowing in and/or out at any given interval of time (6h).
     */
    function setFlowLimit(uint256 flowLimit) external;
}
