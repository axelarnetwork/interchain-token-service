// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatable {
    error NotOperator();
    error NotProposedOperator();

    event OperatorChanged(address operator);

    /**
     * @notice Get the address of the operator
     * @return operator_ of the operator
     */
    function operator() external view returns (address operator_);

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external;

    /**
     * @notice Proposed a change of the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function proposeOperatorChange(address operator_) external;

    /**
     * @notice Accept a proposed change of operatorship
     * @dev Can only be called by the proposed operator
     */
    function acceptOperatorChange() external;
}
