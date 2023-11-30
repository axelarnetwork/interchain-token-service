// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';

import { ITokenManagerLockUnlock } from '../interfaces/ITokenManagerLockUnlock.sol';
import { TokenManager } from './TokenManager.sol';

/**
 * @title TokenManagerLockUnlock
 * @notice This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerLockUnlock is TokenManager, ITokenManagerLockUnlock {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;
    using SafeTokenCall for IERC20;

    /**
     * @notice Constructs an instance of TokenManagerLockUnlock.
     * @dev Calls the constructor of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract.
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    /**
     * @notice Returns the implementation type of the token manager.
     * @return uint256 The implementation type.
     */
    function implementationType() external pure returns (uint256) {
        return uint256(TokenManagerType.LOCK_UNLOCK);
    }

    /**
     * @notice Sets up the token address.
     * @dev The params should be encoded with the token address.
     * @param params_ The setup parameters in bytes.
     */
    function _setup(bytes calldata params_) internal override {
        // The first argument is reserved for the operator.
        (, address tokenAddress_) = abi.decode(params_, (bytes, address));

        /// @dev Keep future compatibility for allowing ITS to manage funds instead of the token manager
        IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20.approve.selector, interchainTokenService, type(uint256).max));
    }

    /**
     * @notice Transfers a specified amount of tokens from a specified address to this contract.
     * @param from The address to transfer tokens from.
     * @param amount The amount of tokens to transfer.
     * @return uint256 The actual amount of tokens transferred. This allows support for fee-on-transfer tokens.
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(this.tokenAddress());

        // slither-disable-next-line var-read-using-this
        try interchainTokenService.transferFromSenderToTokenManager(this.interchainTokenId(), address(token), from, amount) {} catch {
            token.safeTransferFrom(from, address(this), amount);
        }

        return amount;
    }

    /**
     * @notice Transfers a specified amount of tokens from this contract to a specified address.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return uint256 The actual amount of tokens transferred.
     */
    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(this.tokenAddress());

        token.safeTransfer(to, amount);

        return amount;
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @return params_ The resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes memory operator_, address tokenAddress_) external pure returns (bytes memory params_) {
        params_ = abi.encode(operator_, tokenAddress_);
    }
}
