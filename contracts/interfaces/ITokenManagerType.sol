// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerType Interface
 * @notice A simple interface that defines all the token manager types.
 */
interface ITokenManagerType {
    enum TokenManagerType {
        NATIVE_INTERCHAIN_TOKEN, // This type is reserved for interchain tokens deployed by ITS, and can't be used by custom token managers.
        MINT_BURN_FROM, // The token will be minted/burned on transfers. The token needs to give mint permission to the token manager, but burning happens via an approval.
        LOCK_UNLOCK, // The token will be locked/unlocked at the token manager.
        LOCK_UNLOCK_FEE, // The token will be locked/unlocked at the token manager, which will account for any fee-on-transfer behaviour.
        MINT_BURN, // The token will be minted/burned on transfers. The token needs to give mint and burn permission to the token manager.
        GATEWAY // The token will be moved throught the AxelarGateway via callContractWithToken
    }
}
