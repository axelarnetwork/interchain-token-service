// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EVMInterchainTokenService } from '../evm/EVMInterchainTokenService.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title Hyperliquid Interchain Token Service
 * @notice Extended EVM InterchainTokenService with Hyperliquid-specific deployer management
 * @dev Inherits from EVMInterchainTokenService and adds Hyperliquid-specific functionality
 */
contract HyperliquidInterchainTokenService is EVMInterchainTokenService {
    /**
     * @notice Event emitted when a token deployer is updated
     * @param token The address of the token contract
     * @param newDeployer The new deployer address
     * @param operator The operator who performed the update
     */
    event TokenDeployerUpdated(address indexed token, address indexed newDeployer, address indexed operator);

    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        string memory itsHubAddress_,
        address tokenManagerImplementation_,
        address tokenHandler_
    )
        EVMInterchainTokenService(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            gasService_,
            interchainTokenFactory_,
            chainName_,
            itsHubAddress_,
            tokenManagerImplementation_,
            tokenHandler_
        )
    {}

    /**
     * @notice Updates the deployer for a specific Hyperliquid token
     * @dev Only callable by the operator or owner for security
     * @param tokenId The tokenId of the Hyperliquid token
     * @param newDeployer The new deployer address
     */
    function updateTokenDeployer(bytes32 tokenId, address newDeployer) external onlyOperatorOrOwner {
        address tokenAddress = interchainTokenAddress(tokenId);
        if (tokenAddress == address(0)) revert TokenNotFound();

        // Update the deployer in the token contract
        IHyperliquidDeployer(tokenAddress).updateDeployer(newDeployer);

        emit TokenDeployerUpdated(tokenAddress, newDeployer, msg.sender);
    }

    /**
     * @notice Gets the deployer address for a Hyperliquid token
     * @param tokenId The tokenId of the Hyperliquid token
     * @return deployer The deployer address
     */
    function getTokenDeployer(bytes32 tokenId) external view returns (address deployer) {
        address tokenAddress = interchainTokenAddress(tokenId);
        if (tokenAddress == address(0)) revert TokenNotFound();

        return IHyperliquidDeployer(tokenAddress).deployer();
    }

    // ============ Error Definitions ============

    error TokenNotFound();
} 