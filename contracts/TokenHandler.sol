// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { ReentrancyGuard } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/ReentrancyGuard.sol';

import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IERC20MintableBurnable } from './interfaces/IERC20MintableBurnable.sol';
import { IERC20BurnableFrom } from './interfaces/IERC20BurnableFrom.sol';

/**
 * @title TokenHandler
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
contract TokenHandler is ITokenHandler, ITokenManagerType, ReentrancyGuard {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;

    /**
     * @notice This function gives token to a specified address from the token manager.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress The address of the token to give.
     * @param tokenManager The address of the token manager.
     * @param to The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which could be different for certain token type.
     */
    // slither-disable-next-line locked-ether
    function giveToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address to,
        uint256 amount
    ) external payable returns (uint256) {
        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            _giveInterchainToken(tokenAddress, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN) || tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            _mintToken(tokenManager, tokenAddress, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenFrom(tokenAddress, tokenManager, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, tokenManager, to, amount);
            return amount;
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function takes token from a specified address to the token manager.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress The address of the token to give.
     * @param tokenManager The address of the token manager.
     * @param from The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which could be different for certain token type.
     */
    // slither-disable-next-line locked-ether
    function takeToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address from,
        uint256 amount
    ) external payable returns (uint256) {
        if (tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            _takeInterchainToken(tokenAddress, from, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN)) {
            _burnToken(tokenManager, tokenAddress, from, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            _burnTokenFrom(tokenAddress, from, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenFrom(tokenAddress, from, tokenManager, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, from, tokenManager, amount);
            return amount;
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function transfers token from and to a specified address.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress the address of the token to give.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of token to transfer.
     * @return uint256 The amount of token actually transferred, which could be different for certain token type.
     */
    // slither-disable-next-line locked-ether
    function transferTokenFrom(
        uint256 tokenManagerType,
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external payable returns (uint256) {
        if (
            tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN) ||
            tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)
        ) {
            _transferTokenFrom(tokenAddress, from, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, from, to, amount);
            return amount;
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
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
        if (diff < amount) {
            amount = diff;
        }

        return amount;
    }

    function _giveInterchainToken(address tokenAddress, address to, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.mint.selector, to, amount));
    }

    function _takeInterchainToken(address tokenAddress, address from, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.burn.selector, from, amount));
    }

    function _mintToken(address tokenManager, address tokenAddress, address to, uint256 amount) internal {
        ITokenManager(tokenManager).mintToken(tokenAddress, to, amount);
    }

    function _burnToken(address tokenManager, address tokenAddress, address from, uint256 amount) internal {
        ITokenManager(tokenManager).burnToken(tokenAddress, from, amount);
    }

    function _burnTokenFrom(address tokenAddress, address from, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burnFrom.selector, from, amount));
    }
}
