// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOperator } from '../interfaces/IOperator.sol';

/**
 * @title HyperLiquidDeployer
 * @notice This contract explicitly reserves slot 0 for the deployer address.
 * @dev This is specifically for Hyperliquid firstStorageSlot compatibility.
 * Must be inherited first to ensure slot 0 is properly reserved.
 */
abstract contract HyperLiquidDeployer {
    /// @dev Explicitly reserves slot 0 for deployer address
    /// This state variable declaration ensures Solidity places it in slot 0
    address private deployerSlot0;

    error NotAuthorized();

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployer The address of the deployer
     */
    function getDeployer() external view returns (address deployer) {
        assembly {
            // Read directly from slot 0
            deployer := sload(0)
        }
    }

    /**
     * @notice Internal function to set the deployer address in slot 0
     * @param newDeployer The address of the deployer
     */
    function _setDeployer(address newDeployer) internal {
        assembly {
            // Write directly to slot 0
            sstore(0, newDeployer)
        }
    }

    /**
     * @notice Allows the ITS contract or its operator to update the deployer address
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external {
        address its = _getInterchainTokenService();
        if (msg.sender != its) {
            // Check if caller is ITS operator
            if (!IOperator(its).isOperator(msg.sender)) revert NotAuthorized();
        }
        _setDeployer(newDeployer);
    }

    /**
     * @notice Abstract function to get the interchain token service address
     * @return address The interchain token service contract address
     */
    function _getInterchainTokenService() internal view virtual returns (address);
} 