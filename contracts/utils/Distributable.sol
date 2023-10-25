// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDistributable } from '../interfaces/IDistributable.sol';

import { RolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/RolesBase.sol';
import { RolesConstants } from './RolesConstants.sol';

/**
 * @title Distributable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (a distributor) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Distributable is IDistributable, RolesBase, RolesConstants {
    /**
     * @dev Internal function that stores the new distributor address in the correct storage slot
     * @param distributor_ The address of the new distributor
     */
    function _addDistributor(address distributor_) internal {
        uint8[] memory roles = new uint8[](1);
        roles[0] = uint8(Roles.DISTRIBUTOR);
        _addRoles(distributor_, roles);
    }

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor_ The address of the new distributor
     */
    function transferDistributorship(address distributor_) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        uint8[] memory roles = new uint8[](1);
        roles[0] = uint8(Roles.DISTRIBUTOR);
        _transferRoles(msg.sender, distributor_, roles);
    }

    /**
     * @notice Proposed a change of the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor_ The address of the new distributor
     */
    function proposeDistributorship(address distributor_) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        uint8[] memory roles = new uint8[](1);
        roles[0] = uint8(Roles.DISTRIBUTOR);
        _proposeRoles(msg.sender, distributor_, roles);
    }

    /**
     * @notice Accept a change of the distributor of the contract
     * @dev Can only be called by the proposed distributor
     */
    function acceptDistributorship(address fromDistributor) external {
        uint8[] memory roles = new uint8[](1);
        roles[0] = uint8(Roles.DISTRIBUTOR);
        _acceptRoles(fromDistributor, msg.sender, roles);
    }

    /**
     * @notice Query if an address is a distributor
     * @param addr the address to query for
     */
    function isDistributor(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.DISTRIBUTOR));
    }
}
