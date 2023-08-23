// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Pausable
 * @notice This contract provides a mechanism to halt the execution of specific functions
 * if a pause condition is activated.
 */
interface INoReEntrancy {
    error ReEntrancy();

    /**
     * @notice Check if the contract is already executing.
     * @return entered A boolean representing the entered status. True if already executing, false otherwise.
     */
    function hasEntered() external view returns (bool entered);
}
