// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';

import { IBaseTokenManager } from './IBaseTokenManager.sol';
import { IOperator } from './IOperator.sol';
import { IFlowLimit } from './IFlowLimit.sol';

/**
 * @title ITokenManager Interface
 * @notice This contract is responsible for managing tokens, such as setting locking token balances, or setting flow limits, for interchain transfers.
 */
interface ITokenManager is IBaseTokenManager, IOperator, IFlowLimit, IImplementation {
    error TokenLinkerZeroAddress();
    error NotService(address caller);
    error NotSupported();

    /**
     * @notice Returns implementation type of this token manager.
     * @dev This is stored in the proxy and should not be called in the implementation, but it is included here so that the interface properly tells us what functions exist.
     * @return uint256 The implementation type of this token manager.
     */
    function implementationType() external view returns (uint256);

    function addFlowIn(uint256 amount) external;

    function addFlowOut(uint256 amount) external;

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

    /**
     * @notice A function to renew approval to the service if we need to.
     */
    function approveService() external;

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @return params_ The resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes calldata operator_, address tokenAddress_) external pure returns (bytes memory params_);

    /**
     * @notice External function to allow the service to mint tokens through the tokenManager
     * @dev This function should revert if called by anyone but the service.
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param to The recipient.
     * @param amount The amount to mint.
     */
    function mintToken(address tokenAddress_, address to, uint256 amount) external;

    /**
     * @notice External function to allow the service to burn tokens through the tokenManager
     * @dev This function should revert if called by anyone but the service.
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param from The address to burn the token from.
     * @param amount The amount to burn.
     */
    function burnToken(address tokenAddress_, address from, uint256 amount) external;
}
