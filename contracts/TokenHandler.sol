// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { ReentrancyGuard } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/ReentrancyGuard.sol';

import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { IERC20MintableBurnable } from './interfaces/IERC20MintableBurnable.sol';
import { IERC20BurnableFrom } from './interfaces/IERC20BurnableFrom.sol';

/**
 * @title ITokenManager Interface
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
contract TokenHandler is ITokenHandler, ITokenManagerType, ReentrancyGuard {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress The address of the token to give.
     * @param from The address of the sender (usually token manager).
     * @param to The address of the recepient.
     * @return amount The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    // slither-disable-next-line locked-ether
    function giveToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external payable returns (uint256) {
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenLockUnlock(tokenAddress, from, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenLockUnlockFee(tokenAddress, from, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN) || tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            _giveTokenMintBurn(tokenAddress, to, amount);
            return amount;
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param tokenManagerType The token manager type.
     * @param tokenAddress the address of the token to give.
     * @param to The address of the recipient (usually the token manager).
     * @param from the address of the provider.
     * @return amount The amount of tokens actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    // slither-disable-next-line locked-ether
    function takeToken(
        uint256 tokenManagerType,
        address tokenAddress,
        address to,
        address from,
        uint256 amount
    ) external payable returns (uint256) {
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK)) {
            _transferTokenLockUnlock(tokenAddress, from, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenLockUnlockFee(tokenAddress, from, to, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN)) {
            _takeTokenMintBurn(tokenAddress, from, amount);
            return amount;
        }

        if (tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM)) {
            _takeTokenMintBurnFrom(tokenAddress, from, amount);
            return amount;
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    function _transferTokenLockUnlock(address tokenAddress, address from, address to, uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(tokenAddress).safeTransferFrom(from, to, amount);
    }

    function _transferTokenLockUnlockFee(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal noReEntrancy returns (uint256) {
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(to);

        // slither-disable-next-line arbitrary-send-erc20
        IERC20(tokenAddress).safeTransferFrom(from, to, amount);

        uint256 diff = IERC20(tokenAddress).balanceOf(to) - balanceBefore;
        if (diff < amount) {
            amount = diff;
        }

        return amount;
    }

    function _giveTokenMintBurn(address tokenAddress, address to, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.mint.selector, to, amount));
    }

    function _takeTokenMintBurn(address tokenAddress, address from, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.burn.selector, from, amount));
    }

    function _takeTokenMintBurnFrom(address tokenAddress, address from, uint256 amount) internal {
        IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burnFrom.selector, from, amount));
    }
}
