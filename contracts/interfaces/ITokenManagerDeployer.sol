// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenManagerDeployer Interface
 * @notice This interface is used to deploy new instances of the TokenManagerProxy contract.
 */
interface ITokenManagerDeployer {
    error AddressZero();
    error TokenManagerDeploymentFailed();

    /**
     * @notice Deploys a new instance of the TokenManagerProxy contract
     * @param tokenId The unique identifier for the token
     * @param implementationType Token manager implementation type
     * @param params Additional parameters used in the setup of the token manager
     * @return tokenManager Address of the deployed tokenManager
     */
    function deployTokenManager(
        bytes32 tokenId,
        uint256 implementationType,
        bytes calldata params
    ) external payable returns (address tokenManager);
}
