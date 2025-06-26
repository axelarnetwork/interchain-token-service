// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from './InterchainToken.sol';
import { HyperliquidDeployer } from './HyperliquidDeployer.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';
import { IHyperliquidInterchainToken } from '../interfaces/IHyperliquidInterchainToken.sol';

/**
 * @title HyperliquidInterchainToken
 * @notice This contract implements an interchain token with Hyperliquid-specific modifications.
 * @dev Inherits from HyperLiquidDeployer first to ensure slot 0 is properly reserved,
 * then from InterchainToken for standard functionality.
 * This maintains the standard InterchainToken while providing Hyperliquid compatibility.
 */
contract HyperliquidInterchainToken is HyperliquidDeployer, InterchainToken, IHyperliquidInterchainToken {
    error NotService();

    /**
     * @notice Constructs the HyperliquidInterchainToken contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) InterchainToken(interchainTokenServiceAddress) {
        // Don't set service here as it will be set in init() for each proxy
    }

    /**
     * @notice Setup function to initialize contract parameters.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function initHyperliquid(
        bytes32 tokenId_,
        address minter,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external {
        if (_isInitialized()) revert AlreadyInitialized();

        _initialize();

        if (tokenId_ == bytes32(0)) revert TokenIdZero();
        if (bytes(tokenName).length == 0) revert TokenNameEmpty();
        if (bytes(tokenSymbol).length == 0) revert TokenSymbolEmpty();

        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        tokenId = tokenId_;

        // Set the deployer in slot 0 for Hyperliquid compatibility
        _setDeployer(address(0));

        /**
         * @dev Set the token service as a minter to allow it to mint and burn tokens.
         * Also add the provided address as a minter. If `address(0)` was provided,
         * add it as a minter to allow anyone to easily check that no custom minter was set.
         */
        _addMinter(interchainTokenService_);
        _addMinter(minter);

        _setNameHash(tokenName);
    }

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployerAddress The address of the deployer
     */
    function deployer() external view override(HyperliquidDeployer, IHyperliquidInterchainToken) returns (address deployerAddress) {
        return _deployer();
    }

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override(IHyperliquidDeployer, IHyperliquidInterchainToken) {
        if (msg.sender != interchainTokenService_) {
            revert NotService();
        }

        _setDeployer(newDeployer);
    }
}
