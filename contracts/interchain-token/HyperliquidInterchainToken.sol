// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from './InterchainToken.sol';
import { HyperLiquidDeployer } from './HyperLiquidDeployer.sol';

/**
 * @title HyperliquidInterchainToken
 * @notice This contract implements an interchain token with Hyperliquid-specific modifications.
 * @dev Inherits from HyperLiquidDeployer first to ensure slot 0 is properly reserved,
 * then from InterchainToken for standard functionality.
 * This maintains the standard InterchainToken while providing Hyperliquid compatibility.
 */
contract HyperliquidInterchainToken is HyperLiquidDeployer, InterchainToken {
    /**
     * @notice Constructs the HyperliquidInterchainToken contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) InterchainToken(interchainTokenServiceAddress) {
        _setDeployer(msg.sender); // Set initial deployer to msg.sender
    }

    /**
     * @notice Setup function to initialize contract parameters.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function init(
        bytes32 tokenId_,
        address minter,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external override {
        // Copy the parent's init logic to avoid recursion
        if (_isInitialized()) revert AlreadyInitialized();

        _initialize();

        if (tokenId_ == bytes32(0)) revert TokenIdZero();
        if (bytes(tokenName).length == 0) revert TokenNameEmpty();
        if (bytes(tokenSymbol).length == 0) revert TokenSymbolEmpty();

        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        tokenId = tokenId_;

        /**
         * @dev Set the token service as a minter to allow it to mint and burn tokens.
         * Also add the provided address as a minter. If `address(0)` was provided,
         * add it as a minter to allow anyone to easily check that no custom minter was set.
         */
        _addMinter(interchainTokenService());
        _addMinter(minter);

        _setNameHash(tokenName);

        _setDeployer(msg.sender); // Set deployer to msg.sender during initialization
    }

    /**
     * @notice Implementation of the abstract function to get the interchain token service address
     * @return address The interchain token service contract address
     */
    function _getInterchainTokenService() internal view override returns (address) {
        return interchainTokenService();
    }
}
