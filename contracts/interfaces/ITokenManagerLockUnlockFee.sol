// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @title ITokenManagerLockUnlockFee Interface
 * @notice This interface is for a lock/unlock with fee TokenManager
 */
interface ITokenManagerLockUnlockFee is ITokenManager {
    /**
     * @notice Getter function for the parameters of a lock/unlock with fee TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @return params_ The resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes memory operator_, address tokenAddress_) external pure returns (bytes memory params_);
}
