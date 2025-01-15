// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { ReentrancyGuard } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/ReentrancyGuard.sol';
import { Create3AddressFixed } from './utils/Create3AddressFixed.sol';

import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from './interfaces/ITokenManagerProxy.sol';
import { IERC20BurnableFrom } from './interfaces/IERC20BurnableFrom.sol';
import { IMinter } from './interfaces/IMinter.sol';

/**
 * @title TokenHandler
 * @notice This contract is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
contract TokenHandler is ITokenHandler, ITokenManagerType, ReentrancyGuard, Create3AddressFixed {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;

    /**
     * @notice This function gives token to a specified address from the token manager.
     * @param tokenId The token id of the tokenManager.
     * @param to The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which could be different for certain token type.
     * @return address the address of the token.
     */
    function giveToken(bytes32 tokenId, address to, uint256 amount) external returns (uint256, address) {
        address tokenManager = _create3Address(tokenId);

        (uint256 tokenManagerType, address tokenAddress) = ITokenManagerProxy(tokenManager).getImplementationTypeAndTokenAddress();

        _migrateToken(tokenManager, tokenAddress, tokenManagerType);

        /// @dev Track the flow amount being received via the message
        ITokenManager(tokenManager).addFlowIn(amount);

        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            _mintToken(ITokenManager(tokenManager), tokenAddress, to, amount);
        } else if (
            tokenManagerType == uint256(TokenManagerType.MINT_BURN) || tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)
        ) {
            _mintToken(ITokenManager(tokenManager), tokenAddress, to, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenFrom(tokenAddress, tokenManager, to, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, tokenManager, to, amount);
        } else {
            revert UnsupportedTokenManagerType(tokenManagerType);
        }

        return (amount, tokenAddress);
    }

    /**
     * @notice This function takes token from a specified address to the token manager.
     * @param tokenId The tokenId for the token.
     * @param tokenOnly can only be called from the token.
     * @param from The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which could be different for certain token type.
     */
    // slither-disable-next-line locked-ether
    function takeToken(bytes32 tokenId, bool tokenOnly, address from, uint256 amount) external payable returns (uint256) {
        address tokenManager = _create3Address(tokenId);
        (uint256 tokenManagerType, address tokenAddress) = ITokenManagerProxy(tokenManager).getImplementationTypeAndTokenAddress();

        if (tokenOnly && msg.sender != tokenAddress) revert NotToken(msg.sender, tokenAddress);

        _migrateToken(tokenManager, tokenAddress, tokenManagerType);

        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            _burnToken(ITokenManager(tokenManager), tokenAddress, from, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.MINT_BURN)) {
            _burnToken(ITokenManager(tokenManager), tokenAddress, from, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            _burnTokenFrom(tokenAddress, from, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenFrom(tokenAddress, from, tokenManager, amount);
        } else if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, from, tokenManager, amount);
        } else {
            revert UnsupportedTokenManagerType(tokenManagerType);
        }

        /// @dev Track the flow amount being sent out as a message
        ITokenManager(tokenManager).addFlowOut(amount);

        return amount;
    }

    /**
     * @notice This function transfers token from and to a specified address.
     * @param tokenId The token id of the token manager.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of token to transfer.
     * @return uint256 The amount of token actually transferred, which could be different for certain token type.
     * @return address The address of the token corresponding to the input tokenId.
     */
    function transferTokenFrom(bytes32 tokenId, address from, address to, uint256 amount) external returns (uint256, address) {
        address tokenManager = _create3Address(tokenId);
        (uint256 tokenManagerType, address tokenAddress) = ITokenManagerProxy(tokenManager).getImplementationTypeAndTokenAddress();

        if (
            tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN) ||
            tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)
        ) {
            _transferTokenFrom(tokenAddress, from, to, amount);
            return (amount, tokenAddress);
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, from, to, amount);
            return (amount, tokenAddress);
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function prepares a token manager after it is deployed
     * @param tokenManagerType The token manager type.
     * @param tokenManager The address of the token manager.
     */
    // slither-disable-next-line locked-ether
    function postTokenManagerDeploy(uint256 tokenManagerType, ITokenManager tokenManager) external payable {
        // For native interhcain tokens we transfer mintership to the token manager.
        // This is done here because InterchainToken bytecode needs to be fixed.
        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            IMinter(tokenManager.tokenAddress()).transferMintership(address(tokenManager));
            // For lock/unlock token managers, the ITS contract needs an approval from the token manager to transfer tokens on its behalf.
        } else if (
            tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK) || tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)
        ) {
            tokenManager.approveService();
        }
    }

    function _transferTokenFrom(address tokenAddress, address from, address to, uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(tokenAddress).safeTransferFrom(from, to, amount);
    }

    function _transferTokenFromWithFee(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal noReEntrancy returns (uint256) {
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(to);

        _transferTokenFrom(tokenAddress, from, to, amount);

        uint256 diff = IERC20(tokenAddress).balanceOf(to) - balanceBefore;

        return diff < amount ? diff : amount;
    }

    function _mintToken(ITokenManager tokenManager, address tokenAddress, address to, uint256 amount) internal {
        tokenManager.mintToken(tokenAddress, to, amount);
    }

    function _burnToken(ITokenManager tokenManager, address tokenAddress, address from, uint256 amount) internal {
        tokenManager.burnToken(tokenAddress, from, amount);
    }

    function _burnTokenFrom(address tokenAddress, address from, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burnFrom.selector, from, amount));
    }

    /**
     * @notice This transfers mintership of a native Interchain token to the tokenManager if ITS is still its minter.
     * It does nothing if ITS is not the minter. This ensures that interchain tokens are auto-migrated without requiring a downtime for ITS.
     * @param tokenManager The token manager address to transfer mintership to.
     * @param tokenAddress The address of the token to transfer mintership of.
     * @param tokenManagerType The token manager type for the token.
     */
    function _migrateToken(address tokenManager, address tokenAddress, uint256 tokenManagerType) internal {
        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN) && IMinter(tokenAddress).isMinter(address(this))) {
            IMinter(tokenAddress).transferMintership(tokenManager);
        }
    }
}
