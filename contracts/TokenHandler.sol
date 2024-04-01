// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { ReentrancyGuard } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/ReentrancyGuard.sol';
import { Create3Address } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Address.sol';

import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from './interfaces/ITokenManagerProxy.sol';
import { IERC20MintableBurnable } from './interfaces/IERC20MintableBurnable.sol';
import { IERC20BurnableFrom } from './interfaces/IERC20BurnableFrom.sol';
import { IERC20Named } from './interfaces/IERC20Named.sol';

/**
 * @title TokenHandler
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
contract TokenHandler is ITokenHandler, ITokenManagerType, ReentrancyGuard, Create3Address {
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;
    using SafeTokenTransfer for IERC20;

    address public immutable gateway;

    uint256 internal constant UINT256_MAX = type(uint256).max;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert AddressZero();
        gateway = gateway_;
    }

    /**
     * @notice This function gives token to a specified address from the token manager.
     * @param tokenId The token id of the tokenManager.
     * @param to The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which could be different for certain token type.
     * @return address the address of the token.
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
            return (amount, tokenAddress);
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, tokenManager, to, amount);
            return (amount, tokenAddress);
        }

        if (tokenManagerType == uint256(TokenManagerType.GATEWAY)) {
            _transferToken(tokenAddress, to, amount);
            return (amount, tokenAddress);
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
    }

    /**
     * @notice This function takes token from a specified address to the token manager.
     * @param tokenId The tokenId for the token.
     * @param tokenOnly can onky be called from the token.
     * @param from The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which could be different for certain token type.
     * @return symbol The symbol for the token, if not empty the token is a gateway token and a callContractWith token has to be made.
     */
    // slither-disable-next-line locked-ether
    function takeToken(
        bytes32 tokenId,
        bool tokenOnly,
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
            return (amount, symbol);
        }

        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            amount = _transferTokenFromWithFee(tokenAddress, from, tokenManager, amount);
            return (amount, symbol);
        }

        if (tokenManagerType == uint256(TokenManagerType.GATEWAY)) {
            _transferTokenFrom(tokenAddress, from, address(this), amount);
            return (amount, symbol);
        }

        revert UnsupportedTokenManagerType(tokenManagerType);
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
    // slither-disable-next-line locked-ether
    function transferTokenFrom(bytes32 tokenId, address from, address to, uint256 amount) external payable returns (uint256, address) {
        address tokenManager = _create3Address(tokenId);
        (uint256 tokenManagerType, address tokenAddress) = ITokenManagerProxy(tokenManager).getImplementationTypeAndTokenAddress();

        if (
            tokenManagerType == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN) ||
            tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN) ||
            tokenManagerType == uint256(TokenManagerType.MINT_BURN_FROM) ||
            tokenManagerType == uint256(TokenManagerType.GATEWAY)
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
    function postTokenManagerDeploy(uint256 tokenManagerType, address tokenManager) external payable {
        if (tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK) || tokenManagerType == uint256(TokenManagerType.LOCK_UNLOCK_FEE)) {
            ITokenManager(tokenManager).approveService();
        }

        // Approve the gateway here. One-time infinite approval works for gateway wrapped tokens, and for most origin tokens. Approval can be refreshed in the future if needed for certain tokens.
        if (tokenManagerType == uint256(TokenManagerType.GATEWAY)) {
            address token = ITokenManager(tokenManager).tokenAddress();
            _approveGateway(token, UINT256_MAX);
        }
    }

    function _transferTokenFrom(address tokenAddress, address from, address to, uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(tokenAddress).safeTransferFrom(from, to, amount);
    }

    function _transferToken(address tokenAddress, address to, uint256 amount) internal {
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(tokenAddress).safeTransfer(to, amount);
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

    function _approveGateway(address tokenAddress, uint256 amount) internal {
        uint256 allowance = IERC20(tokenAddress).allowance(address(this), gateway);
        if (allowance == 0) {
            IERC20(tokenAddress).safeCall(abi.encodeWithSelector(IERC20.approve.selector, gateway, amount));
        }
    }
}
