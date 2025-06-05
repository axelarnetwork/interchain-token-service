// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenDeployer
 * @notice This interface is used to deploy new instances of the InterchainTokenProxy contract.
 */
interface IInterchainTokenDeployer {
    error AddressZero();
    error TokenDeploymentFailed();

    /**
     * @notice Returns the interchain token implementation address.
     * @return address The interchain token implementation address.
     */
    function implementationAddress() external view returns (address);

    /**
     * @notice Returns the interchain token deployment address.
     * @param salt The deployment salt.
     * @return tokenAddress The token address.
     */
    function deployedAddress(bytes32 salt) external view returns (address tokenAddress);

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract.
     * @param salt The salt used by Create3Deployer.
     * @param tokenId tokenId of the token.
     * @param minter Address of the minter.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @return tokenAddress Address of the deployed token.
     */
    function deployInterchainToken(
        bytes32 salt,
        bytes32 tokenId,
        address minter,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (address tokenAddress);

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract with deployer tracking.
     * @dev NEW FUNCTION: This version stores the deployer address in slot 0 for Hyperliquid compatibility.
     * @param salt The salt used by Create3Deployer.
     * @param tokenId tokenId of the token.
     * @param minter Address of the minter.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @param deployer Address of the deployer (stored in slot 0).
     * @return tokenAddress Address of the deployed token.
     */
    function deployInterchainTokenWithDeployer(
        bytes32 salt,
        bytes32 tokenId,
        address minter,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address deployer
    ) external returns (address tokenAddress);
}
