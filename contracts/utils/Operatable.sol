// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOperatable } from '../interfaces/IOperatable.sol';

/**
 * @title Operatable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (an operator) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Operatable is IOperatable {
    // uint256(keccak256('operator')) - 1
    uint256 internal constant ADMIN_SLOT = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d7;

    /**
     * @dev Throws a NotOperator custom error if called by any account other than the operator.
     */
    modifier onlyOperator() {
        if (operator() != msg.sender) revert NotOperator();
        _;
    }

    /**
     * @notice Get the address of the operator
     * @return operator_ of the operator
     */
    function operator() public view returns (address operator_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            operator_ := sload(ADMIN_SLOT)
        }
    }

    /**
     * @dev Internal function that stores the new operator address in the operator storage slot
     * @param operator_ The address of the new operator
     */
    function _setOperator(address operator_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(ADMIN_SLOT, operator_)
        }
        emit OperatorChanged(operator_);
    }

    /**
     * @notice Change the operator of the contract
     * @dev Can only be called by the current operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external onlyOperator {
        _setOperator(operator_);
    }
}
