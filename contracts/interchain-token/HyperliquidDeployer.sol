// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperliquidDeployer
 * @notice This contract allows setting setting a deployer address associated to an Interchain token.
 * It must be inherited first to ensure the deployer is stored in slot 0, as required by Hyperliquid Core.
 * This is specifically for the linking of Interchain tokens between Hyperliquid EVM and Core
 * where the deployer address used to deploy a spot asset in HyperCore matches the address stored in the first storage slot
 * of the ERC20 token deployed in Hyperliquid EVM via create2 mechanism.
 * ```
 */
abstract contract HyperliquidDeployer is IHyperliquidDeployer {
    /// @dev Constant for slot 0 to avoid magic numbers
    uint256 private constant DEPLOYER_SLOT = 0;
    
    /// @dev Explicitly reserves slot 0 for deployer address
    address private deployerAddress;

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return The address of the deployer
     */
    function _deployer() internal view virtual returns (address) {
        return deployerAddress;
    }

    /**
     * @notice Internal function to set the deployer address in slot 0
     * @param newDeployer The address of the deployer
     */
    function _setDeployer(address newDeployer) internal {
        deployerAddress = newDeployer;
    }

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return The address of the deployer
     */
    function deployer() external view virtual override returns (address) {
        return _deployer();
    }
}
