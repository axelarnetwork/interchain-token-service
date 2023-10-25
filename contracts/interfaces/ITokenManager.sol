// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerType } from './ITokenManagerType.sol';
import { IOperatable } from './IOperatable.sol';
import { IFlowLimit } from './IFlowLimit.sol';
import { IImplementation } from './IImplementation.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
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
     */
    function tokenId() external view returns (bytes32);

    /**
     * @notice A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice A function that should return the implementation type of the token manager.
     */
    function implementationType() external pure returns (uint256);

    /**
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param metadata any additional data to be sent with the transfer.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param data the data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    /**
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender the address of the user paying for the cross chain transfer.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param metadata any additional data to be sent with the transfer.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param destinationAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function takes token to from a specified address. Can only be called by the service.
     * @param sourceAddress the address to take tokens from.
     * @param amount the amount of token to take.
     * @return the amount of token actually taken, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(address sourceAddress, uint256 amount) external returns (uint256);

    /**
     * @notice This function sets the flow limit for this TokenManager. Can only be called by the operator.
     * @param flowLimit the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
     */
    function setFlowLimit(uint256 flowLimit) external;
}
