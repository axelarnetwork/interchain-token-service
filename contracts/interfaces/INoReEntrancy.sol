// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title INoReEntrancy Interface
 * @notice This interface provides a mechanism to prevent re-entrancy attacks by
 * checking the execution status of specific functions.
 */
interface INoReEntrancy {
    error ReEntrancy();

    /**
     * @notice Check if the contract is already executing.
     * @return entered A boolean representing the entered status. True if already executing, false otherwise.
     */
    function hasEntered() external view returns (bool entered);
}
