// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @title ITokenManagerLiquidityPool Interface
 * @notice This interface is for a TokenManager with liquidity pool.
 */
interface ITokenManagerLiquidityPool is ITokenManager {
    /**
     * @notice Getter function for the parameters of a liquidity pool TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @param liquidityPool_ The address of the liquidity pool.
     * @return params The resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(bytes memory operator_, address tokenAddress_, address liquidityPool_) external pure returns (bytes memory params);

    /**
     * @notice Reads the stored liquidity pool address from the specified storage slot.
     * @return liquidityPool_ The address of the liquidity pool.
     */
    function liquidityPool() external view returns (address liquidityPool_);

    /**
     * @notice Updates the address of the liquidity pool.
     * @dev Can only be called by the operator.
     * @param newLiquidityPool The new address of the liquidity pool.
     */
    function setLiquidityPool(address newLiquidityPool) external;
}
