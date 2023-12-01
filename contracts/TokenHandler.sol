// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { ReentrancyGuard } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/ReentrancyGuard.sol';

import { IERC20MintableBurnable } from './interfaces/IERC20MintableBurnable.sol';
import { IERC20BurnableFrom } from './interfaces/IERC20BurnableFrom.sol';

/**
 * @title ITokenManager Interface
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
contract TokenHandler is ITokenHandler, ReentrancyGuard {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress the address of the token to give.
     * @param tokenManager the address of the token manager.
     * @param to the address of the recepient.
     * @return amount The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address to,
        uint256 amount
    ) external payable noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            // slither-disable-next-line arbitrary-send-erc20
            token.safeTransferFrom(tokenManager, to, amount);
            return amount;
        }
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            uint256 balanceBefore = token.balanceOf(to);

            // slither-disable-next-line arbitrary-send-erc20
            token.safeTransferFrom(tokenManager, to, amount);

            uint256 diff = token.balanceOf(to) - balanceBefore;
            if (diff < amount) {
                amount = diff;
            }

            return amount;
        }
        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN) || tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            token.safeCall(abi.encodeWithSelector(IERC20MintableBurnable.mint.selector, to, amount));
            return amount;
        }
        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress the address of the token to give.
     * @param tokenManager the address of the token manager.
     * @param from the address of the provider.
     * @return amount The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address tokenManager,
        address from,
        uint256 amount
    ) external payable noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            token.safeTransferFrom(from, tokenManager, amount);
            return amount;
        }
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            uint256 balanceBefore = token.balanceOf(tokenManager);

            token.safeTransferFrom(from, tokenManager, amount);

            uint256 diff = token.balanceOf(tokenManager) - balanceBefore;
            if (diff < amount) {
                amount = diff;
            }

            return amount;
        }
        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN)) {
            token.safeCall(abi.encodeWithSelector(IERC20MintableBurnable.burn.selector, from, amount));
            return amount;
        }
        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            token.safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burnFrom.selector, from, amount));
            return amount;
        }
        revert UnsupportedTokenManagerType(tokenManagerType);
    }
}
