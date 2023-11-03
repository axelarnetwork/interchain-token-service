// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenDeployer
 * @notice This contract is used to deploy new instances of the InterchainTokenProxy contract.
 */
interface IInterchainTokenDeployer {
    error AddressZero();
    error TokenDeploymentFailed();

    /**
     * @notice Returns the interchain token implementation address
     */
    function implementationAddress() external view returns (address);

    /**
     * @notice Returns the interchain token deployment address.
     * @return tokenAddress the token address.
     */
    function deployedAddress(bytes32 salt) external view returns (address tokenAddress);

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @return tokenAddress Address of the deployed token
     */
    function deployInterchainToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external payable returns (address tokenAddress);
}
