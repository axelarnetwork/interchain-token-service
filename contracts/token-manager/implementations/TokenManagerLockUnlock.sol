// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';

import { ITokenManagerLockUnlock } from '../../interfaces/ITokenManagerLockUnlock.sol';
import { TokenManager } from '../TokenManager.sol';

/**
 * @title TokenManagerLockUnlock
 * @notice This contract is an implementation of TokenManager that locks and unlocks a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerLockUnlock is TokenManager, ITokenManagerLockUnlock {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;

    /**
     * @dev Constructs an instance of TokenManagerLockUnlock. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    function implementationType() external pure returns (uint256) {
        return uint256(TokenManagerType.LOCK_UNLOCK);
    }

    /**
     * @dev Sets up the token address.
     * @param params The setup parameters in bytes. Should be encoded with the token address.
     */
    function _setup(bytes calldata params) internal override {
        // The first argument is reserved for the operator.
        (, address tokenAddress_) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress_);
    }

    /**
     * @dev Transfers a specified amount of tokens from a specified address to this contract.
     * @param from The address to transfer tokens from
     * @param amount The amount of tokens to transfer
     * @return uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens.
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        token.safeTransferFrom(from, address(this), amount);

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

        token.safeTransfer(to, amount);

        return amount;
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator_ the operator of the TokenManager.
     * @param tokenAddress_ the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(bytes memory operator_, address tokenAddress_) external pure returns (bytes memory params) {
        params = abi.encode(operator_, tokenAddress_);
    }
}
