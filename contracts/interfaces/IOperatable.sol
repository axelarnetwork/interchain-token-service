// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatable {
    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function transferOperatorship(address operator_) external;

    /**
     * @notice Proposed a change of the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function proposeOperatorship(address operator_) external;

    /**
     * @notice Accept a proposed change of operatorship
     * @dev Can only be called by the proposed operator
     */
    function acceptOperatorship(address fromOperator) external;


    /**
     * @notice Query if an address is a operator
     * @param addr the address to query for
     */
    function isOpearator(address addr) external view returns (bool);
}
