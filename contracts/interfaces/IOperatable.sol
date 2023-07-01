// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatable {
    error NotOperator();

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
}
