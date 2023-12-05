// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { RolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/RolesBase.sol';

import { IOperator } from '../interfaces/IOperator.sol';

import { RolesConstants } from './RolesConstants.sol';

/**
 * @title Operator Contract
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (a operator) that can be granted exclusive access to
 * specific functions.
 * @dev This module is used through inheritance.
 */
contract Operator is IOperator, RolesBase, RolesConstants {
    /**
     * @notice Internal function that stores the new operator address in the correct storage slot
     * @param operator The address of the new operator
     */
    function _addOperator(address operator) internal {
        _addRole(operator, uint8(Roles.OPERATOR));
    }

    /**
     * @notice Change the operator of the contract.
     * @dev Can only be called by the current operator.
     * @param operator The address of the new operator.
     */
    function transferOperatorship(address operator) external onlyRole(uint8(Roles.OPERATOR)) {
        _transferRole(msg.sender, operator, uint8(Roles.OPERATOR));
    }

    /**
     * @notice Propose a change of the operator of the contract.
     * @dev Can only be called by the current operator.
     * @param operator The address of the new operator.
     */
    function proposeOperatorship(address operator) external onlyRole(uint8(Roles.OPERATOR)) {
        _proposeRole(msg.sender, operator, uint8(Roles.OPERATOR));
    }

    /**
     * @notice Accept a proposed change of operatorship.
     * @dev Can only be called by the proposed operator.
     * @param fromOperator The previous operator of the contract.
     */
    function acceptOperatorship(address fromOperator) external {
        _acceptRole(fromOperator, msg.sender, uint8(Roles.OPERATOR));
    }

    /**
     * @notice Query if an address is a operator.
     * @param addr The address to query for.
     * @return bool Boolean value representing whether or not the address is an operator.
     */
    function isOperator(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.OPERATOR));
    }
}
