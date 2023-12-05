// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMinter } from '../interfaces/IMinter.sol';

import { RolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/RolesBase.sol';
import { RolesConstants } from './RolesConstants.sol';

/**
 * @title Minter Contract
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (a minter) that can be granted exclusive access to
 * specific functions.
 * @dev This module is used through inheritance.
 */
contract Minter is IMinter, RolesBase, RolesConstants {
    /**
     * @notice Internal function that stores the new minter address in the correct storage slot.
     * @param minter_ The address of the new minter.
     */
    function _addMinter(address minter_) internal {
        _addRole(minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Changes the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function transferMinterRole(address minter_) external onlyRole(uint8(Roles.MINTER)) {
        _transferRole(msg.sender, minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Proposes a change of the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function proposeMinterRole(address minter_) external onlyRole(uint8(Roles.MINTER)) {
        _proposeRole(msg.sender, minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Accept a change of the minter of the contract.
     * @dev Can only be called by the proposed minter.
     * @param fromMinter The previous minter.
     */
    function acceptMinterRole(address fromMinter) external {
        _acceptRole(fromMinter, msg.sender, uint8(Roles.MINTER));
    }

    /**
     * @notice Query if an address is a minter
     * @param addr the address to query for
     * @return bool Boolean value representing whether or not the address is a minter.
     */
    function isMinter(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.MINTER));
    }
}
