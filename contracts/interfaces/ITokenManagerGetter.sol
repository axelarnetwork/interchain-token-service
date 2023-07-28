// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';

/**
 * @title ITokenManagerGetter
 * @notice Will provide getters for TokenManager implementations and params to help with deployments.
 */
interface ITokenManagerGetter is ITokenManagerType {
    error LengthMismatch();
    error ZeroAddress();
    error InvalidTokenManagerImplementation();

    /**
     * @notice Returns the parameters for the lock/unlock operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @return params The parameters for the lock/unlock operation.
     */
    function getParamsLockUnlock(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    /**
     * @notice Returns the parameters for the mint/burn operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @return params The parameters for the mint/burn operation.
     */
    function getParamsMintBurn(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);
    
    /**
     * @notice Returns the parameters for the lock/unlock operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @return params The parameters for the lock/unlock operation.
     */
    function getParamsLockUnlockFee(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    /**
     * @notice Returns the parameters for the liquidity pool operation.
     * @param operator The operator address.
     * @param tokenAddress The address of the token.
     * @param liquidityPoolAddress The address of the liquidity pool.
     * @return params The parameters for the liquidity pool operation.
     */
    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) external pure returns (bytes memory params);

    /**
     * @notice Returns the implementation address for a given token manager type.
     * @param tokenManagerType The type of token manager.
     * @return tokenManagerAddress The address of the token manager implementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress);
}
