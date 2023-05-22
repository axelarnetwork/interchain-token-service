// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenLinkerType {
    enum TokenLinkerType {
        LOCK_UNLOCK,
        MINT_BURN,
        DEPLOYED,
        GATEWAY
    }
}
