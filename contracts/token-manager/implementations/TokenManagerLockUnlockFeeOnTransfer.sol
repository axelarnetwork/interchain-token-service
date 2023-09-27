// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManager } from '../TokenManager.sol';
import { NoReEntrancy } from '../../utils/NoReEntrancy.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { SafeTokenTransferFrom, SafeTokenTransfer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

/**
 * @title TokenManagerLockUnlock
 * @notice This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerLockUnlockFee is TokenManager, NoReEntrancy {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;

    /**
     * @dev Constructs an instance of TokenManagerLockUnlock. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    function implementationType() external pure returns (uint256) {
        return uint256(TokenManagerType.LOCK_UNLOCK_FEE_ON_TRANSFER);
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
    function _takeToken(address from, uint256 amount) internal override noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = token.balanceOf(address(this));

        token.safeTransferFrom(from, address(this), amount);

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
    function _giveToken(address to, uint256 amount) internal override noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = IERC20(token).balanceOf(to);

        token.safeTransfer(to, amount);

        uint256 diff = token.balanceOf(to) - balance;
        if (diff < amount) {
            amount = diff;
        }
        return amount;
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(bytes memory operator, address tokenAddress) external pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }
}
