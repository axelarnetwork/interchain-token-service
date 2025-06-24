// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenService } from '../InterchainTokenService.sol';
import { IHyperliquidInterchainToken } from '../interfaces/IHyperliquidInterchainToken.sol';

/**
 * @title HyperliquidInterchainTokenService
 * @notice Extended InterchainTokenService with Hyperliquid-specific deployer management
 * @dev Inherits from InterchainTokenService and adds functionality to manage token deployers
 * This keeps ITS logic separate from token logic, reducing coupling
 */
contract HyperliquidInterchainTokenService is InterchainTokenService {
    constructor(
        address tokenManagerDeployer,
        address interchainTokenDeployer,
        address gateway,
        address gasService,
        address interchainTokenFactory,
        string memory chainName,
        string memory itsHubAddress,
        address tokenManagerImplementation,
        address tokenHandler
    )
        InterchainTokenService(
            tokenManagerDeployer,
            interchainTokenDeployer,
            gateway,
            gasService,
            interchainTokenFactory,
            chainName,
            itsHubAddress,
            tokenManagerImplementation,
            tokenHandler
        )
    {}

    /**
     * @notice Updates the deployer for a specific Hyperliquid token
     * @dev Only callable by the operator or owner for security. This keeps permissioning logic in the service layer
     * @param token The Hyperliquid token contract
     * @param newDeployer The new deployer address
     */
    function updateTokenDeployer(IHyperliquidInterchainToken token, address newDeployer) external onlyOperatorOrOwner {
        // Additional validation: ensure the token is a valid Hyperliquid token
        // This could be enhanced with a registry check if needed
        require(address(token) != address(0), "Invalid token address");
        
        token.updateDeployer(newDeployer);
        
        emit TokenDeployerUpdated(address(token), newDeployer, msg.sender);
    }
    
    /**
     * @notice Event emitted when a token deployer is updated
     * @param token The address of the token contract
     * @param newDeployer The new deployer address
     * @param operator The operator who performed the update
     */
    event TokenDeployerUpdated(address indexed token, address indexed newDeployer, address indexed operator);
} 