// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatable {
    error NotAdmin();

    event AdminChanged(address operator);

    /**
     * @notice Get the address of the operator
     * @return admin_ of the operator
     */
    function operator() external view returns (address admin_);

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param admin_ The address of the new operator
     */
    function setAdmin(address admin_) external;
}
