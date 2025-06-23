// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOperator } from '../interfaces/IOperator.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperLiquidDeployer
 * @notice This contract explicitly reserves slot 0 for the deployer address.
 * This is specifically for the linking of ERC 20 tokens between Hyperliquid EVM and Core
 * where the deployer address used to deploy a spot asset in HyperCore matches the address stored in the first storage slot
 * of the ERC 20 token deployed in Hyperliquid EVM via create2 mechanism.
 * Must be inherited first to ensure slot 0 is properly reserved.
 */
abstract contract HyperliquidDeployer is IHyperliquidDeployer {
    /// @dev Explicitly reserves slot 0 for deployer address
    /// This state variable declaration ensures Solidity places it in slot 0
    address private deployer;

    error NotAuthorized();

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployerAddress The address of the deployer
     */
    function _deployer() internal view virtual returns (address deployerAddress) {
        assembly {
            // Read directly from slot 0
            deployerAddress := sload(0)
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
     * @notice Gets the deployer address stored in slot 0
     * @return deployerAddress The address of the deployer
     */
    function getDeployer() external view virtual override returns (address deployerAddress) {
        return _deployer();
    }

    /**
     * @notice Allows updating the deployer address - authorization logic should be implemented by inheriting contracts
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external virtual override {
        _setDeployer(newDeployer);
    }
}