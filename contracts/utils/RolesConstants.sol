// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title RolesConstants
 * @notice This contract contains enum values representing different contract roles.
 */
contract RolesConstants {
    enum Roles {
        MINTER,
        OPERATOR,
        FLOW_LIMITER
    }
}
