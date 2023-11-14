// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManager } from './ITokenManager.sol';

/**
 * @title ITokenManager
 * @notice This contract is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
interface ITokenManagerMintBurn is ITokenManager {
    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator_ the operator of the TokenManager.
     * @param tokenAddress_ the token to be managed.
     * @return params_ the resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes memory operator_, address tokenAddress_) external pure returns (bytes memory params_);
}
