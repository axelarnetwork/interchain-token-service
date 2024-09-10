// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMulticall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IMulticall.sol';
import { IUpgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol';

import { IInterchainTokenService } from './IInterchainTokenService.sol';

/**
 * @title IInterchainTokenFactory Interface
 * @notice This interface defines functions for deploying new interchain tokens and managing their token managers.
 */
interface IInterchainTokenFactory is IUpgradable, IMulticall {
    error ZeroAddress();
    error InvalidChainName();
    error InvalidMinter(address minter);
    error NotMinter(address minter);
    error NotOperator(address operator);
    error GatewayToken(address tokenAddress);
    error NotServiceOwner(address sender);
    error NotGatewayToken(string symbol);
    error NotSupported();

    /**
     * @notice Returns the address of the interchain token service.
     * @return IInterchainTokenService The address of the interchain token service.
     */
    function interchainTokenService() external view returns (IInterchainTokenService);

    /**
     * @notice Returns the hash of the chain name.
     * @return bytes32 The hash of the chain name.
     */
    function chainNameHash() external view returns (bytes32);

    /**
     * @notice Calculates the salt for an interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param deployer The address of the deployer.
     * @param salt A unique identifier to generate the salt.
     * @return tokenSalt The calculated salt for the interchain token.
     */
    function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) external view returns (bytes32 tokenSalt);

    /**
     * @notice Computes the ID for an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenId The ID of the interchain token.
     */
    function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    /**
     * @notice Retrieves the address of an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenAddress The address of the interchain token.
     */
    function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress);

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @param salt The unique salt for deploying the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals for the token.
     * @param initialSupply The amount of tokens to mint initially (can be zero), allocated to the msg.sender.
     * @param minter The address to receive the initially minted tokens.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply,
        address minter
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param originalChainName The name of the chain where the token originally exists.
     * @param salt The unique salt for deploying the token.
     * @param minter The address to distribute the token on the destination chain.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address minter,
        string memory destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Calculates the salt for a canonical interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param tokenAddress The address of the token.
     * @return tokenSalt The calculated salt for the interchain token.
     */
    function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) external view returns (bytes32 tokenSalt);

    /**
     * @notice Computes the ID for a canonical interchain token based on its address.
     * @param tokenAddress The address of the canonical interchain token.
     * @return tokenId The ID of the canonical interchain token.
     */
    function canonicalInterchainTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    /**
     * @notice Registers a canonical token as an interchain token and deploys its token manager.
     * @param tokenAddress The address of the canonical token.
     * @return tokenId The tokenId corresponding to the registered canonical token.
     */
    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a canonical interchain token on a remote chain.
     * @param originalChain The name of the chain where the token originally exists.
     * @param originalTokenAddress The address of the original token on the original chain.
     * @param destinationChain The name of the chain where the token will be deployed.
     * @param gasValue The gas amount to be sent for deployment.
     * @return tokenId The tokenId corresponding to the deployed canonical InterchainToken.
     */
    function deployRemoteCanonicalInterchainToken(
        string calldata originalChain,
        address originalTokenAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Calculates the salt for a gateway interchain token.
     * @param tokenIdentifier A unique identifier to generate the salt.
     * @return salt The calculated salt for the interchain token.
     */
    function gatewayTokenSalt(bytes32 tokenIdentifier) external pure returns (bytes32 salt);

    /**
     * @notice Register 'canonical' gateway tokens. The same salt needs to be used for the same gateway token on every chain.
     * @param tokenIdentifier A gateway token identifier to be used for the token registration. Should be the same for all chains.
     * @param symbol The symbol of the token to register.
     */
    function registerGatewayToken(bytes32 tokenIdentifier, string calldata symbol) external returns (bytes32 tokenId);
}
