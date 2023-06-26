// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

/**
 * @title ITokenManagerDeployer
 * @notice This contract is used to deploy new instances of the TokenManagerProxy contract.
 */
interface ITokenManagerDeployer {
    error AddressZero();
    error TokenManagerDeploymentFailed();

    /**
     * @notice Getter for the Create3Deployer.
     */
    function deployer() external view returns (Create3Deployer);

    /**
     * @notice Deploys a new instance of the TokenManagerProxy contract
     * @param tokenId The unique identifier for the token
     * @param implementationType Token manager implementation type
     * @param params Additional parameters used in the setup of the token manager
     */
    function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes calldata params) external payable;
}
