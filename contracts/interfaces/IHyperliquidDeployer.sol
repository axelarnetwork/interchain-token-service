// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IHyperliquidDeployer interface
 * @notice Interface for HyperliquidDeployer contract
 * @dev This interface defines the functions that can be overridden
 */
interface IHyperliquidDeployer {
    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployerAddr The address of the deployer
     */
    function deployer() external view returns (address deployerAddr);

    /**
     * @notice Allows updating the deployer address
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external;
}
