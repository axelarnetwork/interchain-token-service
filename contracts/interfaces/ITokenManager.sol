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
     * @notice Returns implementation type of this token manager.
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
    function addServiceApproval() external;

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @return params_ The resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes calldata operator_, address tokenAddress_) external pure returns (bytes memory params_);
}
