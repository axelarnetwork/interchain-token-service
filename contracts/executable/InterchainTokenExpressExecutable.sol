// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { InterchainTokenExecutable } from './InterchainTokenExecutable.sol';

/**
 * @title InterchainTokenExpressExecutable
 * @notice Abstract contract that defines an interface for executing express logic in the context of interchain token operations.
 * @dev This contract extends `InterchainTokenExecutable` to provide express execution capabilities. It is intended to be inherited by contracts
 * that implement express logic for interchain token actions. This contract will only be called by the interchain token service.
 */
abstract contract InterchainTokenExpressExecutable is IInterchainTokenExpressExecutable, InterchainTokenExecutable {
    bytes32 internal constant EXPRESS_EXECUTE_SUCCESS = keccak256('its-express-execute-success');

    /**
     * @notice Creates a new InterchainTokenExpressExecutable contract.
     * @param interchainTokenService_ The address of the interchain token service that will call this contract.
     */
    constructor(address interchainTokenService_) InterchainTokenExecutable(interchainTokenService_) {}

    /**
     * @notice Executes express logic in the context of an interchain token transfer.
     * @dev Only callable by the interchain token service.
     * @param commandId The message id for the call.
     * @param sourceChain The source chain of the token transfer.
     * @param sourceAddress The source address of the token transfer.
     * @param data The data associated with the token transfer.
     * @param tokenId The token ID.
     * @param token The token address.
     * @param amount The amount of tokens to be transferred.
     * @return bytes32 Hash indicating success of the express execution.
     */
    function expressExecuteWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external virtual onlyService returns (bytes32) {
        _executeWithInterchainToken(commandId, sourceChain, sourceAddress, data, tokenId, token, amount);
        return EXPRESS_EXECUTE_SUCCESS;
    }
}
