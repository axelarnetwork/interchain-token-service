// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMulticall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IMulticall.sol';
import { IUpgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol';

import { IInterchainTokenService } from './IInterchainTokenService.sol';
import { ITokenManagerType } from './ITokenManagerType.sol';

/**
 * @title IInterchainTokenFactory Interface
 * @notice This interface defines functions for deploying new interchain tokens and managing their token managers.
 */
interface IInterchainTokenFactory is ITokenManagerType, IUpgradable, IMulticall {
    error ZeroAddress();
    error InvalidChainName();
    error InvalidMinter(address minter);
    error NotMinter(address minter);
    error NotSupported();
    error RemoteDeploymentNotApproved();
    error InvalidTokenId(bytes32 tokenId, bytes32 expectedTokenId);
    error ZeroSupplyToken();
    error NotToken(address tokenAddress);
    error CannotLinkTokenToThisChain();

    /// @notice Emitted when a minter approves a deployer for a remote interchain token deployment that uses a custom destinationMinter address.
    event DeployRemoteInterchainTokenApproval(
        address indexed minter,
        address indexed deployer,
        bytes32 indexed tokenId,
        string destinationChain,
        bytes destinationMinter
    );

    /// @notice Emitted when a minter revokes a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.
    event RevokedDeployRemoteInterchainTokenApproval(
        address indexed minter,
        address indexed deployer,
        bytes32 indexed tokenId,
        string destinationChain
    );

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
     * @notice Computes the deploy salt for an interchain token.
     * @param deployer The address of the deployer.
     * @param salt A unique identifier to generate the salt.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function interchainTokenDeploySalt(address deployer, bytes32 salt) external view returns (bytes32 deploySalt);

    /**
     * @notice Computes the ID for an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenId The ID of the interchain token.
     */
    function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

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
     * @notice Allow the minter to approve the deployer for a remote interchain token deployment that uses a custom destinationMinter address.
     * This ensures that a token deployer can't choose the destinationMinter itself, and requires the approval of the minter to reduce trust assumptions on the deployer.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param destinationMinter The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes
     * since the encoding of the account is dependent on the destination chain.
     */
    function approveDeployRemoteInterchainToken(
        address deployer,
        bytes32 salt,
        string calldata destinationChain,
        bytes calldata destinationMinter
    ) external;

    /**
     * @notice Allows the minter to revoke a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     */
    function revokeDeployRemoteInterchainToken(address deployer, bytes32 salt, string calldata destinationChain) external;

    /**
     * @notice Deploys a remote interchain token on a specified destination chain. No additional minter is set on the deployed token.
     * Use the `deployRemoteInterchainTokenWithMinter` method to do so.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteInterchainToken(
        bytes32 salt,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param salt The unique salt for deploying the token.
     * @param minter The address to distribute the token on the destination chain.
     * @param destinationChain The name of the destination chain.
     * @param destinationMinter The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes
     * since the encoding of the account is dependent on the destination chain. If this is empty, then the `minter` of the token on the current chain
     * is used as the destination minter, which makes it convenient when deploying to other EVM chains.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteInterchainTokenWithMinter(
        bytes32 salt,
        address minter,
        string calldata destinationChain,
        bytes memory destinationMinter,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deprecated: Use `deployRemoteInterchainToken` or `deployRemoteInterchainTokenWithMinter` instead.
     * Deploys a remote interchain token on a specified destination chain.
     * @dev originalChainName is only allowed to be '', i.e the current chain.
     * Other source chains are not supported anymore to simplify ITS token deployment behaviour.
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
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Computes the deploy salt for a canonical interchain token.
     * @param tokenAddress The address of the token.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function canonicalInterchainTokenDeploySalt(address tokenAddress) external view returns (bytes32 deploySalt);

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
     * @param originalTokenAddress The address of the original token on the original chain.
     * @param destinationChain The name of the chain where the token will be deployed.
     * @param gasValue The gas amount to be sent for deployment.
     * @return tokenId The tokenId corresponding to the deployed canonical InterchainToken.
     */
    function deployRemoteCanonicalInterchainToken(
        address originalTokenAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a canonical interchain token on a remote chain.
     * This method is deprecated and will be removed in the future. Please use the above method instead.
     * @dev originalChain is only allowed to be '', i.e the current chain.
     * Other source chains are not supported anymore to simplify ITS token deployment behaviour.
     * @param originalChain The name of the chain where the token originally exists.
     * @param originalTokenAddress The address of the original token on the original chain.
     * @param destinationChain The name of the chain where the token will be deployed.
     * @param gasValue The gas amount to be sent for deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteCanonicalInterchainToken(
        string calldata originalChain,
        address originalTokenAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Computes the deploy salt for a linked interchain token.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function linkedTokenDeploySalt(address deployer, bytes32 salt) external view returns (bytes32 deploySalt);

    /**
     * @notice Computes the ID for a linked token based on its address.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @return tokenId The ID of the linked token.
     */
    function linkedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    /**
     * @notice Register an existing ERC20 token under a `tokenId` computed from the provided `salt`.
     * The token metadata must have been registered for tokens on each chain via `InterchainTokenService.registerTokenMetadata`.
     * This token can then be linked to remote tokens on different chains by submitting the `linkToken` function from the same `msg.sender` and using the same `salt`.
     * @dev This function is marked as payable since it can be called within a multicall with other payable methods.
     * @param salt The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId.
     * @param tokenAddress The token address of the token being registered.
     * @param tokenManagerType The token manager type used for the token link.
     * @param operator The operator of the token manager.
     */
    function registerCustomToken(
        bytes32 salt,
        address tokenAddress,
        TokenManagerType tokenManagerType,
        address operator
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Links a remote token on `destinationChain` to a local token corresponding to the `tokenId` computed from the provided `salt`.
     * A local token must have been registered first using the `registerCustomToken` function.
     * @param salt The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId.
     * @param destinationChain The name of the destination chain.
     * @param destinationTokenAddress The token address of the token being linked.
     * @param tokenManagerType The token manager type used for the token link.
     * @param linkParams Additional parameters for the token link depending on the destination chain. For EVM destination chains, this is an optional custom operator address.
     * @param gasValue The cross-chain gas value used to link the token on the destination chain.
     * @return tokenId The tokenId corresponding to the linked token.
     */
    function linkToken(
        bytes32 salt,
        string calldata destinationChain,
        bytes calldata destinationTokenAddress,
        TokenManagerType tokenManagerType,
        bytes calldata linkParams,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Links a remote token on `destinationChain` to a local token corresponding to the `tokenId` computed from the provided `salt`.
     * A local token must have been registered first using the `registerCustomToken` function.
     * @param salt The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId.
     * @param destinationChain The name of the destination chain.
     * @param name The token name on destination chain.
     * @param symbol The token symbol on destination chain.
     * @param decimals The token decimals on destination chain.
     * @param linkParams Additional parameters for the token link depending on the destination chain. For EVM destination chains, this is an optional custom operator address.
     * @param gasValue The cross-chain gas value used to link the token on the destination chain.
     * @return tokenId The tokenId corresponding to the linked token.
     */
    function linkAsInterchainToken(
        bytes32 salt,
        string calldata destinationChain,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes calldata linkParams,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);
}
