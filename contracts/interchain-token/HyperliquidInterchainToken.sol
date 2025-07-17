// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from './InterchainToken.sol';
import { HyperliquidDeployer } from './HyperliquidDeployer.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperliquidInterchainToken
 * @notice This contract implements an interchain token with Hyperliquid-specific modifications.
 * @dev Inherits from HyperliquidDeployer to allow storing a deployer address in the token to a custom storage slot,
 * then from InterchainToken for standard functionality.
 * This maintains the standard InterchainToken while providing Hyperliquid compatibility.
 */
contract HyperliquidInterchainToken is HyperliquidDeployer, InterchainToken, IHyperliquidDeployer {
    error NotService(address caller);

    /**
     * @notice Modifier to restrict access to only the interchain token service
     */
    modifier onlyService() {
        if (msg.sender != interchainTokenService_) {
            revert NotService(msg.sender);
        }
        _;
    }

    /**
     * @notice Constructs the HyperliquidInterchainToken contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) InterchainToken(interchainTokenServiceAddress) {}

    /**
     * @notice Gets the deployer address
     * @return deployerAddr The address of the deployer
     */
    function deployer() external view override returns (address deployerAddr) {
        return _deployer();
    }

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override onlyService {
        _setDeployer(newDeployer);
    }
}
