// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AbstractInterchainTokenService } from '../abstract/AbstractInterchainTokenService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IWHBAR } from './IWHBAR.sol';
import { HTS } from './HTS.sol';
import { IHederaTokenService } from './IHederaTokenService.sol';
import { TokenCreationPricing } from '../utils/TokenCreationPricing.sol';

/**
 * @title Hedera Interchain Token Service
 * @notice Hedera-specific implementation of the Interchain Token Service
 * @dev Implements HTS token operations with WHBAR integration for fees
 */
contract HederaInterchainTokenService is AbstractInterchainTokenService, TokenCreationPricing {
    IWHBAR public immutable whbar;

    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        string memory itsHubAddress_,
        address tokenManagerImplementation_,
        address tokenHandler_,
        address whbarAddress_
    )
        AbstractInterchainTokenService(
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
        TokenCreationPricing(whbarAddress_)
    {
        whbar = IWHBAR(whbarAddress_);
    }

    // ============ Hedera-Specific Implementations ============

    /**
     * @notice Deploy interchain token using HTS precompile
     * @dev HTS tokens don't have deterministic addresses
     */
    function _deployInterchainToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address owner,
        bytes memory operator
    ) internal virtual override returns (address tokenAddress) {
        // HTS token creation requires fee payment
        uint256 creationPrice = _getTokenCreationPrice();
        if (msg.value < creationPrice) revert InsufficientFee();

        // Create HTS token via precompile
        IHederaTokenService.HederaToken memory token = IHederaTokenService.HederaToken({
            name: name,
            symbol: symbol,
            treasury: address(this), // Treasury must be creator
            memo: string(abi.encodePacked("ITS Token: ", tokenId)),
            tokenSupplyType: IHederaTokenService.TokenSupplyType.FINITE,
            maxSupply: type(int64).max,
            freezeDefault: false,
            keys: new IHederaTokenService.TokenKey[](0),
            expiry: IHederaTokenService.Expiry({
                second: 0,
                autoRenewAccount: address(0),
                autoRenewPeriod: 0
            })
        });

        // Deploy token via HTS
        tokenAddress = HTS.createFungibleToken(
            token,
            0, // No initial supply (Hedera limitation)
            int32(decimals),
            creationPrice
        );

        // Transfer WHBAR fee to token creation
        if (creationPrice > 0) {
            whbar.transfer(address(this), creationPrice);
        }
    }

    /**
     * @notice Get token address from registry (non-deterministic for HTS)
     */
    function _getTokenAddress(bytes32 tokenId) internal view virtual override returns (address tokenAddress) {
        // For HTS, we need to use registered token address instead of deterministic derivation
        // This would be stored in a mapping or retrieved from a registry
        revert("HTS tokens don't have deterministic addresses");
    }

    /**
     * @notice Get token creation price in WHBAR
     */
    function _getTokenCreationPrice() internal view virtual override returns (uint256 price) {
        return tokenCreationPrice();
    }

    /**
     * @notice HTS token transfer via precompile
     */
    function _transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal virtual override returns (bool success) {
        try HTS.transferToken(token, from, to, int64(amount)) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice HTS token minting via precompile
     */
    function _mintToken(
        address token,
        address to,
        uint256 amount
    ) internal virtual override returns (bool success) {
        try HTS.mintToken(token, uint64(amount), new IHederaTokenService.TokenKey[](0)) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice HTS token burning via precompile
     */
    function _burnToken(
        address token,
        address from,
        uint256 amount
    ) internal virtual override returns (bool success) {
        try HTS.burnToken(token, uint64(amount), new IHederaTokenService.TokenKey[](0)) {
            return true;
        } catch {
            return false;
        }
    }

    // ============ Hedera-Specific Public Functions ============

    /**
     * @notice Get registered token address for Hedera
     */
    function registeredTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        // Implementation would query a registry for the token address
        // This replaces the deterministic interchainTokenAddress function
    }

    // ============ Hedera-Specific Admin Functions ============

    /**
     * @notice Set token creation price
     */
    function setTokenCreationPrice(uint256 price) external onlyOperator {
        _setTokenCreationPrice(price);
    }

    /**
     * @notice Get WHBAR balance for token creation
     */
    function getWhbarBalance() external view returns (uint256 balance) {
        return whbar.balanceOf(address(this));
    }

    // ============ Error Definitions ============

    error InsufficientFee();
} 