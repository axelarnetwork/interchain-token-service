// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { SafeTokenTransferFrom, SafeTokenTransfer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

/**
 * @title TokenManagerLockUnlock
 * @notice This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerLockUnlockFee is TokenManagerAddressStorage {
    /**
     * @dev Constructs an instance of TokenManagerLockUnlock. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManagerAddressStorage(interchainTokenService_) {}

    function implementationType() external pure returns (uint256) {
        return 2;
    }

    /**
     * @dev Sets up the token address.
     * @param params The setup parameters in bytes. Should be encoded with the token address.
     */
    function _setup(bytes calldata params) internal override {
        // The first argument is reserved for the operator.
        (, address tokenAddress) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress);
    }

    /**
     * @dev Transfers a specified amount of tokens from a specified address to this contract.
     * @param from The address to transfer tokens from
     * @param amount The amount of tokens to transfer
     * @return uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens.
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = token.balanceOf(address(this));

        SafeTokenTransferFrom.safeTransferFrom(token, from, address(this), amount);

        uint256 diff = token.balanceOf(address(this)) - balance;
        if (diff < amount) {
            amount = diff;
        }
        return amount;
    }

    /**
     * @dev Transfers a specified amount of tokens from this contract to a specified address.
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return uint The actual amount of tokens transferred
     */
    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = IERC20(token).balanceOf(to);

        SafeTokenTransfer.safeTransfer(token, to, amount);

        return IERC20(token).balanceOf(to) - balance;
    }
}
