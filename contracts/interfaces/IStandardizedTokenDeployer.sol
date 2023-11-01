// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

/**
 * @title IStandardizedTokenDeployer Interface
 * @notice This interface is used to deploy new instances of the StandardizedTokenProxy contract.
 */
interface IStandardizedTokenDeployer {
    error AddressZero();
    error TokenDeploymentFailed();

    /**
     * @notice Returns the standardized token implementation address.
     * @return address The standardized token implementation address.
     */
    function implementationAddress() external view returns (address);

    /**
     * @notice Returns the standardized token deployment address.
     * @param salt The deployment salt.
     * @return tokenAddress The token address.
     */
    function deployedAddress(bytes32 salt) external view returns (address tokenAddress);

    /**
     * @notice Deploys a new instance of the StandardizedTokenProxy contract.
     * @param salt The salt used by Create3Deployer.
     * @param tokenManager Address of the token manager.
     * @param distributor Address of the distributor.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @param mintAmount Amount of tokens to mint initially.
     * @param mintTo Address to mint initial tokens to.
     */
    function deployStandardizedToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) external payable;
}
