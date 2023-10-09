// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
interface ITokenManagerLockUnlock is ITokenManager {
    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator_ the operator of the TokenManager.
     * @param tokenAddress_ the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(bytes memory operator_, address tokenAddress_) external pure returns (bytes memory params);
}
