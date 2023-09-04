// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerType
 * @notice A simple interface that defines all the token manager types
 */
interface ITokenManagerType {
    enum TokenManagerType {
        LOCK_UNLOCK,
        MINT_BURN,
        LOCK_UNLOCK_FEE_ON_TRANSFER,
        LIQUIDITY_POOL
    }
}
