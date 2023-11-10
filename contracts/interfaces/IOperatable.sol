// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IRolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IRolesBase.sol';

/**
 * @title IOperatable Interface
 * @notice An interface for a contract module which provides a basic access control mechanism, where
 * there is an account (a operator) that can be granted exclusive access to specific functions.
 */
interface IOperatable is IRolesBase {
    /**
     * @notice Change the operator of the contract.
     * @dev Can only be called by the current operator.
     * @param operator_ The address of the new operator.
     */
    function transferOperatorship(address operator_) external;

    /**
     * @notice Proposed a change of the operator of the contract.
     * @dev Can only be called by the current operator.
     * @param operator_ The address of the new operator.
     */
    function proposeOperatorship(address operator_) external;

    /**
     * @notice Accept a proposed change of operatorship.
     * @dev Can only be called by the proposed operator.
     * @param fromOperator The previous operator of the contract.
     */
    function acceptOperatorship(address fromOperator) external;

    /**
     * @notice Query if an address is a operator.
     * @param addr The address to query for.
     * @return bool Boolean value representing whether or not the address is an operator.
     */
    function isOperator(address addr) external view returns (bool);
}
