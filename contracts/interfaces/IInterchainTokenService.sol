// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarValuedExpressExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarValuedExpressExecutable.sol';
import { IMulticall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IMulticall.sol';
import { IPausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IPausable.sol';
import { IUpgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol';

import { ITransmitInterchainToken } from './ITransmitInterchainToken.sol';
import { ITokenManager } from './ITokenManager.sol';
import { ITokenManagerType } from './ITokenManagerType.sol';
import { ITokenManagerImplementation } from './ITokenManagerImplementation.sol';
import { IOperator } from './IOperator.sol';
import { IChainTracker } from './IChainTracker.sol';

/**
 * @title IInterchainTokenService Interface
 * @notice Interface for the Interchain Token Service
 */
interface IInterchainTokenService is
    ITransmitInterchainToken,
    ITokenManagerType,
    ITokenManagerImplementation,
    IAxelarValuedExpressExecutable,
    IOperator,
    IPausable,
    IMulticall,
    IChainTracker,
    IUpgradable
{
    error InvalidChainName();
    error NotRemoteService();
    error TokenManagerDoesNotExist(bytes32 tokenId);
    error ExecuteWithInterchainTokenFailed(address contractAddress);
    error ExpressExecuteWithInterchainTokenFailed(address contractAddress);
    error TokenManagerDeploymentFailed(bytes error);
    error InterchainTokenDeploymentFailed(bytes error);
    error InvalidMessageType(uint256 messageType);
    error InvalidMetadataVersion(uint32 version);
    error InvalidExpressMessageType(uint256 messageType);
    error TakeTokenFailed(bytes data);
    error GiveTokenFailed(bytes data);
    error TokenHandlerFailed(bytes data);
    error EmptyData();
    error PostDeployFailed(bytes data);
    error ZeroAmount();
    error CannotDeploy(TokenManagerType);
    error CannotDeployRemotelyToSelf();
    error InvalidPayload();
    error GatewayCallFailed(bytes data);
    error EmptyTokenName();
    error EmptyTokenSymbol();
    error EmptyParams();
    error EmptyDestinationAddress();
    error EmptyTokenAddress();
    error NotSupported();
    error NotInterchainTokenFactory(address sender);
    error InvalidHubAddress();

    event InterchainTransfer(
        bytes32 indexed tokenId,
        address indexed sourceAddress,
        string destinationChain,
        bytes destinationAddress,
        uint256 amount,
        bytes32 indexed dataHash
    );
    event InterchainTransferReceived(
        bytes32 indexed commandId,
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 dataHash
    );
    event TokenMetadataRegistered(address indexed tokenAddress, uint8 decimals);
    event LinkTokenStarted(
        bytes32 indexed tokenId,
        string destinationChain,
        bytes sourceTokenAddress,
        bytes destinationTokenAddress,
        TokenManagerType indexed tokenManagerType,
        bytes params
    );
    event InterchainTokenDeploymentStarted(
        bytes32 indexed tokenId,
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimals,
        bytes minter,
        string destinationChain
    );
    event TokenManagerDeployed(bytes32 indexed tokenId, address tokenManager, TokenManagerType indexed tokenManagerType, bytes params);
    event InterchainTokenDeployed(
        bytes32 indexed tokenId,
        address tokenAddress,
        address indexed minter,
        string name,
        string symbol,
        uint8 decimals
    );
    event InterchainTokenIdClaimed(bytes32 indexed tokenId, address indexed deployer, bytes32 indexed salt);

    /**
     * @notice Returns the address of the token manager deployer contract.
     * @return tokenManagerDeployerAddress The address of the token manager deployer contract.
     */
    function tokenManagerDeployer() external view returns (address tokenManagerDeployerAddress);

    /**
     * @notice Returns the address of the interchain token deployer contract.
     * @return interchainTokenDeployerAddress The address of the interchain token deployer contract.
     */
    function interchainTokenDeployer() external view returns (address interchainTokenDeployerAddress);

    /**
     * @notice Returns the address of TokenManager implementation.
     * @return tokenManagerAddress_ The address of the token manager contract.
     */
    function tokenManager() external view returns (address tokenManagerAddress_);

    /**
     * @notice Returns the address of TokenHandler implementation.
     * @return tokenHandlerAddress The address of the token handler contract.
     */
    function tokenHandler() external view returns (address tokenHandlerAddress);

    /**
     * @notice Returns the address of the interchain token factory.
     * @return address The address of the interchain token factory.
     */
    function interchainTokenFactory() external view returns (address);

    /**
     * @notice Returns the hash of the chain name.
     * @return bytes32 The hash of the chain name.
     */
    function chainNameHash() external view returns (bytes32);

    /**
     * @notice Returns the address of the token manager associated with the given tokenId.
     * @param tokenId The tokenId of the token manager.
     * @return tokenManagerAddress_ The address of the token manager.
     */
    function tokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress_);

    /**
     * @notice Returns the instance of ITokenManager from a specific tokenId.
     * @param tokenId The tokenId of the deployed token manager.
     * @return tokenManager_ The instance of ITokenManager associated with the specified tokenId.
     */
    function deployedTokenManager(bytes32 tokenId) external view returns (ITokenManager tokenManager_);

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId The tokenId of the registered token.
     * @return tokenAddress The address of the token.
     */
    function registeredTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    /**
     * @notice Returns the address of the interchain token associated with the given tokenId.
     * @param tokenId The tokenId of the interchain token.
     * @return tokenAddress The address of the interchain token.
     */
    function interchainTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    /**
     * @notice Returns the custom tokenId associated with the given operator and salt.
     * @param operator_ The operator address.
     * @param salt The salt used for token id calculation.
     * @return tokenId The custom tokenId associated with the operator and salt.
     */
    function interchainTokenId(address operator_, bytes32 salt) external view returns (bytes32 tokenId);

    /**
     * @notice Registers metadata for a token on the ITS Hub. This metadata is used for scaling linked tokens.
     * The token metadata must be registered before linkToken can be called for the corresponding token.
     * @param tokenAddress The address of the token.
     * @param gasValue The cross-chain gas value for sending the registration message to ITS Hub.
     */
    function registerTokenMetadata(address tokenAddress, uint256 gasValue) external payable;

    /**
     * @notice Only to be used by the InterchainTokenFactory to register custom tokens to this chain. Then link token can be used to register those tokens to other chains.
     * @param salt A unique salt to derive tokenId from.
     * @param tokenManagerType The type of the token manager to use for the token registration.
     * @param linkParams The operator for the token.
     */
    function registerCustomToken(
        bytes32 salt,
        address tokenAddress,
        TokenManagerType tokenManagerType,
        bytes calldata linkParams
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice If `destinationChain` is an empty string, this function will register the token address on the current chain.
     * Otherwise, it will link the token address on the destination chain with the token corresponding to the tokenId on the current chain.
     * A token manager is deployed on EVM chains that's responsible for managing the linked token.
     * @dev This function replaces the prior `deployTokenManager` function.
     * @param salt A unique identifier to allow for multiple tokens registered per deployer.
     * @param destinationChain The chain to link the token to. Pass an empty string for this chain.
     * @param destinationTokenAddress The token address to link, as bytes.
     * @param tokenManagerType The type of the token manager to use to send and receive tokens.
     * @param linkParams Additional parameteres to use to link the token. Fow not it is just the address of the operator.
     * @param gasValue Pass a non-zero value only for remote linking, which should be the gas to use to pay for the contract call.
     * @return tokenId The tokenId associated with the token manager.
     */
    function linkToken(
        bytes32 salt,
        string calldata destinationChain,
        bytes memory destinationTokenAddress,
        TokenManagerType tokenManagerType,
        bytes memory linkParams,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys and registers an interchain token on a remote chain.
     * @param salt The salt used for token deployment.
     * @param destinationChain The name of the destination chain. Use '' for this chain.
     * @param name The name of the interchain tokens.
     * @param symbol The symbol of the interchain tokens.
     * @param decimals The number of decimals for the interchain tokens.
     * @param minter The minter data for mint/burn operations.
     * @param gasValue The gas value for deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployInterchainToken(
        bytes32 salt,
        string calldata destinationChain,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory minter,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId);

    /**
     * @notice Initiates an interchain transfer of a specified token to a destination chain.
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The address on the destination chain to send the tokens to.
     * @param amount The amount of tokens to be transferred.
     * @param metadata Optional metadata for the call for additional effects (such as calling a destination contract).
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Sets the flow limits for multiple tokens.
     * @param tokenIds An array of tokenIds.
     * @param flowLimits An array of flow limits corresponding to the tokenIds.
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external;

    /**
     * @notice Allows the owner to pause/unpause the token service.
     * @param paused whether to pause or unpause.
     */
    function setPauseStatus(bool paused) external;

    /**
     * @notice Allows the owner to migrate legacy tokens that cannot be migrated automatically.
     * @param tokenId the tokenId of the registered token.
     */
    function migrateInterchainToken(bytes32 tokenId) external;
}
