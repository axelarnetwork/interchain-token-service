// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenService } from '../InterchainTokenService.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperliquidInterchainTokenService
 * @notice Extended InterchainTokenService with Hyperliquid-specific deployer management
 * @dev Inherits from InterchainTokenService and adds functionality to manage token deployers
 * This keeps ITS logic separate from token logic, reducing coupling
 */
contract HyperliquidInterchainTokenService is InterchainTokenService {
    /**
     * @notice Error thrown when a token does not support the IHyperliquidDeployer interface
     * @param token The address of the token that doesn't support the interface
     */
    error TokenDoesNotSupportHyperliquidInterface(address token);

    /**
     * @notice Event emitted when a token deployer is updated
     * @param token The address of the token contract
     * @param newDeployer The new deployer address
     * @param operator The operator who performed the update
     */
    event TokenDeployerUpdated(address indexed token, address indexed newDeployer, address indexed operator);

    /**
     * @notice Checks if a token supports the IHyperliquidDeployer interface
     * @param token The token address to check
     * @return True if the token supports the interface
     */
    function _supportsHyperliquidInterface(address token) internal view returns (bool) {
        // Check for deployer() function
        (bool deployerSuccess, ) = token.staticcall(abi.encodeWithSelector(IHyperliquidDeployer.deployer.selector));
        return deployerSuccess;
    }

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
        InterchainTokenService(
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
     * @dev Only callable by the operator or owner for security. This keeps permissioning logic in the service layer
     * @param tokenId The tokenId of the Hyperliquid token
     * @param newDeployer The new deployer address
     */
    function updateTokenDeployer(bytes32 tokenId, address newDeployer) external onlyOperatorOrOwner {

        address tokenAddress = registeredTokenAddress(tokenId);

        if (!_supportsHyperliquidInterface(tokenAddress)) {
            revert TokenDoesNotSupportHyperliquidInterface(tokenAddress);
        }

        // Emit event first (checks-effects-interactions pattern)
        emit TokenDeployerUpdated(tokenAddress, newDeployer, msg.sender);

        // Make external call last
        IHyperliquidDeployer token = IHyperliquidDeployer(tokenAddress);
        token.updateDeployer(newDeployer);
    }
}
