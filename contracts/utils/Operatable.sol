// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOperatable } from '../interfaces/IOperatable.sol';

import { RolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/RolesBase.sol';
import { RolesConstants } from './RolesConstants.sol';

/**
 * @title Operatable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (a operator) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Operatable is IOperatable, RolesBase, RolesConstants {
    /**
     * @dev Internal function that stores the new operator address in the correct storage slot
     * @param operator_ The address of the new operator
     */
    function _addOperator(address operator_) internal {
        uint8[] memory roles = new uint8[](1);
        roles[0] = OPERATOR;
        _addRoles(operator_, roles);
    }

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function transferOperatorship(address operator_) external onlyRole(OPERATOR) {
        uint8[] memory roles = new uint8[](1);
        roles[0] = OPERATOR;
        _transferRoles(msg.sender, operator_, roles);
    }

    /**
     * @notice Proposed a change of the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function proposeOperatorship(address operator_) external onlyRole(OPERATOR) {
        uint8[] memory roles = new uint8[](1);
        roles[0] = OPERATOR;
        _proposeRoles(msg.sender, operator_, roles);
    }

    /**
     * @notice Accept a change of the operator of the contract
     * @dev Can only be called by the proposed operator
     */
    function acceptOperatorship(address fromOperator) external {
        uint8[] memory roles = new uint8[](1);
        roles[0] = OPERATOR;
        _acceptRoles(fromOperator, msg.sender, roles);
    }
}
