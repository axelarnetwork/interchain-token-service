// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerType
 * @notice A simple interface that defines all the token manager types
 */
interface ITokenManagerType {
    enum TokenManagerType {
        MINT_BURN,
        MINT_BURN_FROM,
        MINT_BURN_FROM_ADDRESS,
        LOCK_UNLOCK,
        LOCK_UNLOCK_FEE_ON_TRANSFER,
        LIQUIDITY_POOL
    }
}
