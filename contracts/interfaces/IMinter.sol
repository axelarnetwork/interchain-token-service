// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IRolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IRolesBase.sol';

/**
 * @title IMinter Interface
 * @notice An interface for a contract module which provides a basic access control mechanism, where
 * there is an account (a minter) that can be granted exclusive access to specific functions.
 */
interface IMinter is IRolesBase {
    /**
     * @notice Change the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function transferMintership(address minter_) external;

    /**
     * @notice Proposed a change of the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function proposeMintership(address minter_) external;

    /**
     * @notice Accept a change of the minter of the contract.
     * @dev Can only be called by the proposed minter.
     * @param fromMinter The previous minter.
     */
    function acceptMintership(address fromMinter) external;

    /**
     * @notice Query if an address is a minter
     * @param addr the address to query for
     * @return bool Boolean value representing whether or not the address is a minter.
     */
    function isMinter(address addr) external view returns (bool);
}
