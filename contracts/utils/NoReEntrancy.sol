// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { INoReEntrancy } from '../interfaces/INoReEntrancy.sol';

/**
 * @title Pausable
 * @notice This contract provides a mechanism to halt the execution of specific functions
 * if a pause condition is activated.
 */
contract NoReEntrancy is INoReEntrancy {
    // uint256(keccak256('entered')) - 1
    uint256 internal constant ENTERED_SLOT = 0x01f33dd720a8dea3c4220dc5074a2239fb442c4c775306a696f97a7c54f785fc;
    uint256 internal constant NOT_ENTERED = 1;
    uint256 internal constant HAS_ENTERED = 2;

    /**
     * @notice A modifier that throws a ReEntrancy custom error if the contract is entered
     * @dev This modifier should be used with functions that can be entered twice
     */
    modifier noReEntrancy() {
        if (hasEntered()) revert ReEntrancy();
        _setEntered(HAS_ENTERED);
        _;
        _setEntered(NOT_ENTERED);
    }

    /**
     * @notice Check if the contract is already executing.
     * @return entered A boolean representing the entered status. True if already executing, false otherwise.
     */
    function hasEntered() public view returns (bool entered) {
        assembly {
            entered := eq(sload(ENTERED_SLOT), HAS_ENTERED)
        }
    }

    /**
     * @notice Sets the entered status of the contract
     * @param entered A boolean representing the entered status. True if already executing, false otherwise.
     */
    function _setEntered(uint256 entered) internal {
        assembly {
            sstore(ENTERED_SLOT, entered)
        }
    }
}
