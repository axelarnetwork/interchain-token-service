// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IOperatable Interface
 * @notice This interface defines functions for managing operator roles in a contract.
 */
interface IOperatable {
    error NotOperator();
    error NotProposedOperator();

    event OperatorshipTransferred(address indexed operator);
    event OperatorChangeProposed(address indexed operator);

    /**
     * @notice Get the address of the operator.
     * @return operator_ The operator of the contract.
     */
    function operator() external view returns (address operator_);

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
     */
    function acceptOperatorship() external;
}
