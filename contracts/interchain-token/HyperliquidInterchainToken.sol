// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from './InterchainToken.sol';
import { HyperliquidDeployer } from './HyperliquidDeployer.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperliquidInterchainToken
 * @notice This contract implements an interchain token with Hyperliquid-specific modifications.
 * @dev Inherits from HyperLiquidDeployer first to ensure slot 0 is properly reserved,
 * then from InterchainToken for standard functionality.
 * This maintains the standard InterchainToken while providing Hyperliquid compatibility.
 */
contract HyperliquidInterchainToken is HyperliquidDeployer, InterchainToken, IHyperliquidDeployer {
    error NotService();

    /**
     * @notice Constructs the HyperliquidInterchainToken contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) InterchainToken(interchainTokenServiceAddress) {
        // Set the deployer in slot 0 for Hyperliquid compatibility
        _setDeployer(address(0));
    }

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployerAddress The address of the deployer
     */
    function deployer() external view override returns (address deployerAddress) {
        return _deployer();
    }

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override {
        if (msg.sender != interchainTokenService_) {
            revert NotService();
        }

        _setDeployer(newDeployer);
    }
}
