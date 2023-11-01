// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDistributable } from '../interfaces/IDistributable.sol';

import { RolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/RolesBase.sol';
import { RolesConstants } from './RolesConstants.sol';

/**
 * @title Distributable Contract
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (a distributor) that can be granted exclusive access to
 * specific functions.
 * @dev This module is used through inheritance.
 */
contract Distributable is IDistributable, RolesBase, RolesConstants {
    /**
     * @notice Internal function that stores the new distributor address in the correct storage slot.
     * @param distributor_ The address of the new distributor.
     */
    function _addDistributor(address distributor_) internal {
        _addRole(distributor_, uint8(Roles.DISTRIBUTOR));
    }

    /**
     * @notice Changes the distributor of the contract.
     * @dev Can only be called by the current distributor.
     * @param distributor_ The address of the new distributor.
     */
    function transferDistributorship(address distributor_) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _transferRole(msg.sender, distributor_, uint8(Roles.DISTRIBUTOR));
    }

    /**
     * @notice Proposes a change of the distributor of the contract.
     * @dev Can only be called by the current distributor.
     * @param distributor_ The address of the new distributor.
     */
    function proposeDistributorship(address distributor_) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _proposeRole(msg.sender, distributor_, uint8(Roles.DISTRIBUTOR));
    }

    /**
     * @notice Accept a change of the distributor of the contract.
     * @dev Can only be called by the proposed distributor.
     */
    function acceptDistributorship(address fromDistributor) external {
        _acceptRole(fromDistributor, msg.sender, uint8(Roles.DISTRIBUTOR));
    }

    /**
     * @notice Query if an address is a distributor
     * @param addr the address to query for
     */
    function isDistributor(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.DISTRIBUTOR));
    }
}
