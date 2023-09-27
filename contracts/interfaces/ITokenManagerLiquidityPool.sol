// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
interface ITokenManagerLiquidityPool is ITokenManager {
    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(bytes memory operator, address tokenAddress, address liquidityPool) external pure returns (bytes memory params);

    /**
     * @dev Reads the stored liquidity pool address from the specified storage slot
     * @return liquidityPool_ The address of the liquidity pool
     */
    function liquidityPool() external view returns (address liquidityPool_);

    /**
     * @dev Updates the address of the liquidity pool. Can only be called by the operator.
     * @param newLiquidityPool The new address of the liquidity pool
     */
    function setLiquidityPool(address newLiquidityPool) external;
}
