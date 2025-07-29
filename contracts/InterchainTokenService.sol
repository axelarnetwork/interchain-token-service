// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { ExpressExecutorTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/express/ExpressExecutorTracker.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Pausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Pausable.sol';
import { InterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/InterchainAddressTracker.sol';

import { IInterchainTokenService } from './interfaces/IInterchainTokenService.sol';
import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { ITokenManagerDeployer } from './interfaces/ITokenManagerDeployer.sol';
import { IInterchainTokenDeployer } from './interfaces/IInterchainTokenDeployer.sol';
import { IInterchainTokenExecutable } from './interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenExpressExecutable } from './interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IERC20Named } from './interfaces/IERC20Named.sol';
import { IMinter } from './interfaces/IMinter.sol';
import { Create3AddressFixed } from './utils/Create3AddressFixed.sol';
import { Operator } from './utils/Operator.sol';
import { ChainTracker } from './utils/ChainTracker.sol';
import { ItsHubAddressTracker } from './utils/ItsHubAddressTracker.sol';

/**
 * @title The Interchain Token Service
 * @notice This contract is responsible for facilitating interchain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for interchain transfers to happen.
 * @dev The only storage used in this contract is for Express calls.
 * Furthermore, no ether is intended to or should be sent to this contract except as part of deploy/interchainTransfer payable methods for gas payment.
 */
contract InterchainTokenService is
    Upgradable,
    Operator,
    Pausable,
    Multicall,
    Create3AddressFixed,
    ExpressExecutorTracker,
    InterchainAddressTracker,
    ChainTracker,
    ItsHubAddressTracker,
    IInterchainTokenService
{
    using AddressBytes for bytes;
    using AddressBytes for address;

    /**
     * @dev There are two types of Axelar Gateways for cross-chain messaging:
     * 1. Cross-chain messaging (GMP): The Axelar Gateway allows sending cross-chain messages.
     *    This is compatible across both Amplifier and consensus chains. IAxelarGateway interface exposes this functionality.
     * 2. Cross-chain messaging with Gateway Token: The AxelarGateway on legacy consensus EVM connections supports this (via callContractWithToken)
     *    but not Amplifier chains. The gateway is cast to IAxelarGatewayWithToken when gateway tokens need to be handled.
     *    ITS deployments on Amplifier chains will revert when this functionality is used.
     */
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;
    address public immutable interchainTokenFactory;
    bytes32 public immutable chainNameHash;

    address public immutable interchainTokenDeployer;
    address public immutable tokenManagerDeployer;

    /**
     * @dev Token manager implementation addresses
     */
    address public immutable tokenManager;
    address public immutable tokenHandler;

    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_ID = keccak256('its-interchain-token-id');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('its-interchain-token-salt');

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');
    bytes32 private constant EXECUTE_SUCCESS = keccak256('its-execute-success');
    bytes32 private constant EXPRESS_EXECUTE_SUCCESS = keccak256('its-express-execute-success');

    /**
     * @dev The message types that are sent between InterchainTokenService on different chains.
     */

    uint256 private constant MESSAGE_TYPE_INTERCHAIN_TRANSFER = 0;
    uint256 private constant MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 1;
    // uint256 private constant MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 2;
    uint256 private constant MESSAGE_TYPE_SEND_TO_HUB = 3;
    uint256 private constant MESSAGE_TYPE_RECEIVE_FROM_HUB = 4;
    uint256 private constant MESSAGE_TYPE_LINK_TOKEN = 5;
    uint256 private constant MESSAGE_TYPE_REGISTER_TOKEN_METADATA = 6;

    /**
     * @dev Tokens and token managers deployed via the Token Factory contract use a special deployer address.
     * This removes the dependency on the address the token factory was deployed too to be able to derive the same tokenId.
     */
    address internal constant TOKEN_FACTORY_DEPLOYER = address(0);

    /**
     * @dev Latest version of metadata that's supported.
     */
    uint32 internal constant METADATA_CONTRACT_CALL = 0;

    /**
     * @dev Chain name where ITS Hub exists. This is used for routing ITS calls via ITS hub.
     * This is set as a constant, since the ITS Hub will exist on Axelar.
     */
    string internal constant ITS_HUB_CHAIN_NAME = 'axelar';
    bytes32 internal constant ITS_HUB_CHAIN_NAME_HASH = keccak256(bytes(ITS_HUB_CHAIN_NAME));

    /**
     * @notice Constructor for the Interchain Token Service.
     * @dev All of the variables passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ The address of the TokenManagerDeployer.
     * @param interchainTokenDeployer_ The address of the InterchainTokenDeployer.
     * @param gateway_ The address of the AxelarGateway.
     * @param gasService_ The address of the AxelarGasService.
     * @param interchainTokenFactory_ The address of the InterchainTokenFactory.
     * @param chainName_ The name of the chain that this contract is deployed on.
     * @param itsHubAddress_ The address of the ITS Hub.
     * @param tokenManagerImplementation_ The tokenManager implementation.
     * @param tokenHandler_ The tokenHandler implementation.
     */
    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        string memory itsHubAddress_,
        address tokenManagerImplementation_,
        address tokenHandler_
    ) ItsHubAddressTracker(itsHubAddress_) {
        if (
            gasService_ == address(0) ||
            tokenManagerDeployer_ == address(0) ||
            interchainTokenDeployer_ == address(0) ||
            gateway_ == address(0) ||
            interchainTokenFactory_ == address(0) ||
            tokenManagerImplementation_ == address(0) ||
            tokenHandler_ == address(0)
        ) revert ZeroAddress();

        gateway = IAxelarGateway(gateway_);
        gasService = IAxelarGasService(gasService_);
        tokenManagerDeployer = tokenManagerDeployer_;
        interchainTokenDeployer = interchainTokenDeployer_;
        interchainTokenFactory = interchainTokenFactory_;

        if (bytes(chainName_).length == 0) revert InvalidChainName();
        chainNameHash = keccak256(bytes(chainName_));

        tokenManager = tokenManagerImplementation_;
        tokenHandler = tokenHandler_;
    }

    /*******\
    MODIFIERS
    \*******/

    /**
     * @notice This modifier is used to ensure that only a remote InterchainTokenService can invoke the execute function.
     * @param sourceChain The source chain of the contract call.
     * @param sourceAddress The source address that the call came from.
     */
    modifier onlyItsHub(string calldata sourceChain, string calldata sourceAddress) {
        if (keccak256(bytes(sourceChain)) != ITS_HUB_CHAIN_NAME_HASH || keccak256(bytes(sourceAddress)) != itsHubAddressHash)
            revert NotItsHub();

        _;
    }

    /**
     * @notice This modifier is used to ensure that only an operator or the owner can call a function
     */
    modifier onlyOperatorOrOwner() {
        address sender = msg.sender;

        if (!hasRole(sender, uint8(Roles.OPERATOR)) && sender != owner()) revert NotOperatorOrOwner(sender);

        _;
    }

    /**
     * @notice This modifier is used to ensure that only a the token factory can call a function.
     */
    modifier onlyTokenFactory() {
        if (msg.sender != interchainTokenFactory) revert NotInterchainTokenFactory(msg.sender);

        _;
    }

    /*****\
    GETTERS
    \*****/

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id of this contract.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Calculates the address of a TokenManager from a specific tokenId.
     * @dev The TokenManager does not need to exist already.
     * @param tokenId The tokenId.
     * @return tokenManagerAddress_ The deployment address of the TokenManager.
     */
    function tokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_) {
        tokenManagerAddress_ = _create3Address(tokenId);
    }

    /**
     * @notice Returns the instance of ITokenManager from a specific tokenId.
     * @dev This function checks if a token manager contract exists at the address for the specified tokenId.
     * If no token manager is deployed for the tokenId, the function will revert with `TokenManagerDoesNotExist`.
     * @param tokenId The tokenId of the deployed token manager.
     * @return tokenManager_ The instance of ITokenManager associated with the specified tokenId.
     */
    function deployedTokenManager(bytes32 tokenId) public view returns (ITokenManager tokenManager_) {
        address tokenManagerAddress_ = tokenManagerAddress(tokenId);
        if (tokenManagerAddress_.code.length == 0) revert TokenManagerDoesNotExist(tokenId);
        tokenManager_ = ITokenManager(tokenManagerAddress_);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @dev This function requires that a token manager is already deployed for the specified tokenId.
     * It will call `deployedTokenManager` to get the token manager and return the address of the associated token.
     * @param tokenId The tokenId of the registered token.
     * @return tokenAddress The address of the token.
     */
    function registeredTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenAddress = ITokenManager(deployedTokenManager(tokenId)).tokenAddress();
    }

    /**
     * @notice Returns the address of the interchain token associated with the given tokenId.
     * @dev The token does not need to exist.
     * @param tokenId The tokenId of the interchain token.
     * @return tokenAddress The address of the interchain token.
     */
    function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenId = _getInterchainTokenSalt(tokenId);
        tokenAddress = _create3Address(tokenId);
    }

    /**
     * @notice Calculates the tokenId that would correspond to a link for a given deployer with a specified salt.
     * @param sender The address of the TokenManager deployer.
     * @param salt The salt that the deployer uses for the deployment.
     * @return tokenId The tokenId that the custom TokenManager would get (or has gotten).
     */
    function interchainTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_ID, sender, salt));
    }

    /**
     * @notice Getter function for TokenManager implementation. This will mainly be called by TokenManager proxies
     * to figure out their implementations.
     * @return tokenManagerAddress The address of the TokenManager implementation.
     */
    function tokenManagerImplementation(uint256 /*tokenManagerType*/) external view returns (address) {
        return tokenManager;
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Registers metadata for a token on the ITS Hub. This metadata is used for scaling linked tokens.
     * The token metadata must be registered before linkToken can be called for the corresponding token.
     * @param tokenAddress The address of the token.
     * @param gasValue The cross-chain gas value for sending the registration message to ITS Hub.
     */
    function registerTokenMetadata(address tokenAddress, uint256 gasValue) external payable {
        if (tokenAddress == address(0)) revert EmptyTokenAddress();

        uint8 decimals = IERC20Named(tokenAddress).decimals();

        bytes memory payload = abi.encode(MESSAGE_TYPE_REGISTER_TOKEN_METADATA, tokenAddress.toBytes(), decimals);

        emit TokenMetadataRegistered(tokenAddress, decimals);

        _sendToHub(payload, gasValue);
    }

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
    ) external payable whenNotPaused onlyTokenFactory returns (bytes32 tokenId) {
        // Custom token managers can't be deployed with native interchain token type, which is reserved for interchain tokens
        if (tokenManagerType == TokenManagerType.NATIVE_INTERCHAIN_TOKEN) revert CannotDeploy(tokenManagerType);

        address deployer = TOKEN_FACTORY_DEPLOYER;

        tokenId = interchainTokenId(deployer, salt);

        emit InterchainTokenIdClaimed(tokenId, deployer, salt);

        _deployTokenManager(tokenId, tokenManagerType, tokenAddress, linkParams);
    }

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
        bytes calldata destinationTokenAddress,
        TokenManagerType tokenManagerType,
        bytes calldata linkParams,
        uint256 gasValue
    ) public payable whenNotPaused returns (bytes32 tokenId) {
        if (destinationTokenAddress.length == 0) revert EmptyTokenAddress();

        // Custom token managers can't be deployed with native interchain token type, which is reserved for interchain tokens
        if (tokenManagerType == TokenManagerType.NATIVE_INTERCHAIN_TOKEN) revert CannotDeploy(tokenManagerType);

        // Cannot deploy to this chain using linkToken anymore
        if (bytes(destinationChain).length == 0) {
            revert NotSupported();
        }

        // Cannot deploy to this chain using linkToken anymore
        if (chainNameHash == keccak256(bytes(destinationChain))) revert CannotDeployRemotelyToSelf();

        address deployer = msg.sender;

        if (deployer == interchainTokenFactory) {
            deployer = TOKEN_FACTORY_DEPLOYER;
        }

        tokenId = interchainTokenId(deployer, salt);

        emit InterchainTokenIdClaimed(tokenId, deployer, salt);

        bytes memory sourceTokenAddress = registeredTokenAddress(tokenId).toBytes();

        emit LinkTokenStarted(tokenId, destinationChain, sourceTokenAddress, destinationTokenAddress, tokenManagerType, linkParams);

        bytes memory payload = abi.encode(
            MESSAGE_TYPE_LINK_TOKEN,
            tokenId,
            tokenManagerType,
            sourceTokenAddress,
            destinationTokenAddress,
            linkParams
        );

        _routeMessage(destinationChain, payload, gasValue);
    }

    /**
     * @notice Used to deploy an interchain token alongside a TokenManager in another chain.
     * @dev At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls.
     * If minter is empty bytes, no additional minter is set on the token, only ITS is allowed to mint.
     * If the token is being deployed on the current chain, minter should correspond to an EVM address (as bytes).
     * Otherwise, an encoding appropriate to the destination chain should be used.
     * @param salt The salt to be used during deployment.
     * @param destinationChain The name of the destination chain to deploy to.
     * @param name The name of the token to be deployed.
     * @param symbol The symbol of the token to be deployed.
     * @param decimals The decimals of the token to be deployed.
     * @param minter The address that will be able to mint and burn the deployed token.
     * @param gasValue The amount of native tokens to be used to pay for gas for the remote deployment.
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
    ) external payable whenNotPaused onlyTokenFactory returns (bytes32 tokenId) {
        address deployer = TOKEN_FACTORY_DEPLOYER;

        tokenId = interchainTokenId(deployer, salt);

        emit InterchainTokenIdClaimed(tokenId, deployer, salt);

        if (bytes(destinationChain).length == 0) {
            address tokenAddress = _deployInterchainToken(tokenId, minter, name, symbol, decimals);

            _deployTokenManager(tokenId, TokenManagerType.NATIVE_INTERCHAIN_TOKEN, tokenAddress, minter);
        } else {
            if (chainNameHash == keccak256(bytes(destinationChain))) revert CannotDeployRemotelyToSelf();

            _deployRemoteInterchainToken(tokenId, name, symbol, decimals, minter, destinationChain, gasValue);
        }
    }

    /**
     * @notice Returns the amount of token that this call is worth.
     * @dev If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address on the source chain.
     * @param payload The payload sent with the call.
     * @return address The token address.
     * @return uint256 The value the call is worth.
     */
    function contractCallValue(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) public view virtual onlyItsHub(sourceChain, sourceAddress) whenNotPaused returns (address, uint256) {
        return _contractCallValue(payload);
    }

    /**
     * @notice Executes the cross-chain ITS message.
     * @param commandId The unique message id.
     * @param sourceChain The chain where the transaction originates from.
     * @param sourceAddress The address of the remote ITS where the transaction originates from.
     * @param payload The encoded data payload for the transaction.
     */
    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external onlyItsHub(sourceChain, sourceAddress) whenNotPaused {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();

        _execute(commandId, sourceChain, sourceAddress, payload, payloadHash);
    }

    /**
     * @notice Express executes operations based on the payload and selector.
     * @dev This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions.
     * @param commandId The unique message id.
     * @param sourceChain The chain where the transaction originates from.
     * @param sourceAddress The address of the remote ITS where the transaction originates from.
     * @param payload The encoded data payload for the transaction.
     */
    function expressExecute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes memory payload
    ) public payable whenNotPaused {
        bytes32 payloadHash = keccak256(payload);
        uint256 messageType;
        string memory originalSourceChain;
        (messageType, originalSourceChain, payload) = _decodeHubMessage(payload);

        if (messageType != MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            revert InvalidExpressMessageType(messageType);
        }

        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted();

        address expressExecutor = msg.sender;

        emit ExpressExecuted(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _setExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _expressExecute(commandId, originalSourceChain, payload);
    }

    /**
     * @notice Returns the express executor for a given command.
     * @param commandId The commandId for the contractCall.
     * @param sourceChain The source chain.
     * @param sourceAddress The source address.
     * @param payloadHash The hash of the payload.
     * @return expressExecutor The address of the express executor.
     */
    function getExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external view returns (address expressExecutor) {
        expressExecutor = _getExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash);
    }

    /**
     * @notice Initiates an interchain transfer of a specified token to a destination chain.
     * @dev This is the base version of interchainTransfer that handles simple token transfers without additional metadata or gas value customization.
     *
     * The `destinationAddress` must be correctly encoded depending on the destination chain.
     * - For encoding reference: https://github.com/axelarnetwork/axelar-contract-deployments/tree/main/common#interchain-token-service
     *
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The address on the destination chain to send the tokens to.
     * @param amount The amount of tokens to be transferred.
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable whenNotPaused {
        _interchainTransfer(tokenId, destinationChain, destinationAddress, amount, '', msg.value);
    }

    /**
     * @notice Initiates an interchain transfer to a destination contract. The destination contract will be executed with the provided data. The destination contract must implement the `InterchainTokenExecutable` interface.
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The contract address on the destination chain to send the tokens to and execute.
     * @param amount The amount of tokens to be transferred.
     * @param data Additional data to be provided to the destination contract when executed along with the token transfer.
     */
    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes memory data
    ) external payable whenNotPaused {
        if (data.length == 0) revert EmptyData();

        _interchainTransfer(tokenId, destinationChain, destinationAddress, amount, data, msg.value);
    }

    /**
     * @notice Deprecated: Use the simpler `interchainTransfer` or `callContractWithInterchainToken` instead.
     * Initiates an interchain transfer of a specified token to a destination chain.
     * @dev This version allows for customized metadata and gas value.
     * - The first 4 bytes of `metadata` specify the metadata version.
     * - To call the `destinationAddress` as a contract with a payload, provide `bytes.concat(bytes4(0), payload)` as the metadata.
     * - The token will be transferred to the destination app contract before it is executed.
     * - `gasValue` specifies the native token amount to be paid for covering the cross-chain execution gas.
     *
     * The `destinationAddress` must be correctly encoded depending on the destination chain.
     * - For encoding reference: https://github.com/axelarnetwork/axelar-contract-deployments/tree/main/common#interchain-token-service
     *
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The address on the destination chain to send the tokens to.
     * @param amount The amount of tokens to be transferred.
     * @param metadata Optional metadata containing execution instructions (e.g. contract call payload).
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata,
        uint256 gasValue
    ) external payable whenNotPaused {
        bytes memory data = _decodeMetadata(metadata);

        _interchainTransfer(tokenId, destinationChain, destinationAddress, amount, data, gasValue);
    }

    /******************\
    TOKEN ONLY FUNCTIONS
    \******************/

    /**
     * @notice Transmit an interchain transfer for the given tokenId.
     * @dev Only callable by a token registered under a tokenId.
     * @param tokenId The tokenId of the token (which must be the msg.sender).
     * @param sourceAddress The address where the token is coming from.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of token to give.
     * @param metadata Optional metadata for the call for additional effects (such as calling a destination contract).
     */
    function transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable whenNotPaused {
        amount = _takeToken(tokenId, sourceAddress, amount, true);

        bytes memory data = _decodeMetadata(metadata);

        _transmitInterchainTransfer(tokenId, sourceAddress, destinationChain, destinationAddress, amount, data, msg.value);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds An array of the tokenIds of the tokenManagers to set the flow limits of.
     * @param flowLimits The flowLimits to set.
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyRole(uint8(Roles.OPERATOR)) {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();

        for (uint256 i; i < length; ++i) {
            // slither-disable-next-line calls-loop
            deployedTokenManager(tokenIds[i]).setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to set a trusted address for a chain.
     * @param chainName The chain to set the trusted address of.
     */
    function setTrustedChain(string memory chainName) external onlyOperatorOrOwner {
        _setTrustedChain(chainName);
    }

    /**
     * @notice Used to remove a trusted address for a chain.
     * @param chainName The chain to set the trusted address of.
     */
    function removeTrustedChain(string memory chainName) external onlyOperatorOrOwner {
        _removeTrustedChain(chainName);
    }

    /**
     * @notice Allows the owner to pause/unpause the token service.
     * @param paused Boolean value representing whether to pause or unpause.
     */
    function setPauseStatus(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Allows the owner to migrate minter of native interchain tokens from ITS to the corresponding token manager.
     * @param tokenId the tokenId of the registered token.
     */
    function migrateInterchainToken(bytes32 tokenId) external onlyOwner {
        ITokenManager tokenManager_ = deployedTokenManager(tokenId);
        address tokenAddress = tokenManager_.tokenAddress();
        IMinter(tokenAddress).transferMintership(address(tokenManager_));
    }

    /****************\
    INTERNAL FUNCTIONS
    \****************/

    function _setup(bytes calldata params) internal override {
        (address operator, string memory chainName_, string[] memory trustedChainNames) = abi.decode(params, (address, string, string[]));
        if (operator == address(0)) revert ZeroAddress();
        if (bytes(chainName_).length == 0 || keccak256(bytes(chainName_)) != chainNameHash) revert InvalidChainName();

        _addOperator(operator);
        _setChainName(chainName_);

        uint256 length = trustedChainNames.length;
        for (uint256 i; i < length; ++i) {
            string memory trustedChainName = trustedChainNames[i];
            _setTrustedChain(trustedChainName);
            // Migration: Remove previously set trusted addresses.
            if (trustedAddressHash(trustedChainName) != 0) {
                _removeTrustedAddress(trustedChainName);
            }
        }
    }

    /**
     * @notice Processes the payload data for a send token call.
     * @param commandId The unique message id.
     * @param expressExecutor The address of the express executor. Equals `address(0)` if it wasn't expressed.
     * @param sourceChain The chain where the transaction originates from.
     * @param payload The encoded data payload to be processed.
     */
    function _processInterchainTransferPayload(
        bytes32 commandId,
        address expressExecutor,
        string memory sourceChain,
        bytes memory payload
    ) internal {
        bytes32 tokenId;
        bytes memory sourceAddress;
        address destinationAddress;
        uint256 amount;
        bytes memory data;
        {
            bytes memory destinationAddressBytes;
            (, tokenId, sourceAddress, destinationAddressBytes, amount, data) = abi.decode(
                payload,
                (uint256, bytes32, bytes, bytes, uint256, bytes)
            );
            destinationAddress = destinationAddressBytes.toAddress();
        }

        // Return token to the express executor
        if (expressExecutor != address(0)) {
            _giveToken(tokenId, expressExecutor, amount);
            return;
        }

        address tokenAddress;
        (amount, tokenAddress) = _giveToken(tokenId, destinationAddress, amount);

        // slither-disable-next-line reentrancy-events
        emit InterchainTransferReceived(
            commandId,
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data.length == 0 ? bytes32(0) : keccak256(data)
        );

        if (data.length != 0) {
            bytes32 result = IInterchainTokenExecutable(destinationAddress).executeWithInterchainToken(
                commandId,
                sourceChain,
                sourceAddress,
                data,
                tokenId,
                tokenAddress,
                amount
            );

            if (result != EXECUTE_SUCCESS) revert ExecuteWithInterchainTokenFailed(destinationAddress);
        }
    }

    /**
     * @notice Processes a deploy token manager payload.
     */
    function _processLinkTokenPayload(string memory sourceChain, bytes memory payload) internal {
        (
            ,
            bytes32 tokenId,
            TokenManagerType tokenManagerType,
            bytes memory sourceTokenAddress,
            bytes memory destinationTokenAddress,
            bytes memory linkParams
        ) = abi.decode(payload, (uint256, bytes32, TokenManagerType, bytes, bytes, bytes));

        if (tokenManagerType == TokenManagerType.NATIVE_INTERCHAIN_TOKEN) revert CannotDeploy(tokenManagerType);

        emit LinkTokenReceived(tokenId, sourceChain, sourceTokenAddress, destinationTokenAddress, tokenManagerType, linkParams);

        _deployTokenManager(tokenId, tokenManagerType, destinationTokenAddress.toAddress(), linkParams);
    }

    /**
     * @notice Processes a deploy interchain token manager payload.
     * @param payload The encoded data payload to be processed.
     */
    function _processDeployInterchainTokenPayload(bytes memory payload) internal {
        (, bytes32 tokenId, string memory name, string memory symbol, uint8 decimals, bytes memory minterBytes) = abi.decode(
            payload,
            (uint256, bytes32, string, string, uint8, bytes)
        );
        address tokenAddress;

        tokenAddress = _deployInterchainToken(tokenId, minterBytes, name, symbol, decimals);

        _deployTokenManager(tokenId, TokenManagerType.NATIVE_INTERCHAIN_TOKEN, tokenAddress, minterBytes);
    }

    /**
     * @notice Route the ITS message to the destination chain with the given payload via the ITS Hub.
     * @param destinationChain The target chain where the contract will be called. The destinationChain must be set as trusted.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _routeMessage(string memory destinationChain, bytes memory payload, uint256 gasValue) internal {
        if (!isTrustedChain(destinationChain)) revert UntrustedChain();

        payload = abi.encode(MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload);
        destinationChain = ITS_HUB_CHAIN_NAME;

        _sendToHub(payload, gasValue);
    }

    /**
     * @notice Calls a contract on a destination chain via the gateway caller.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _sendToHub(bytes memory payload, uint256 gasValue) internal {
        string memory hubAddress = itsHubAddress();

        if (gasValue > 0) {
            _payGas(hubAddress, payload, gasValue);
        }

        gateway.callContract(ITS_HUB_CHAIN_NAME, hubAddress, payload);
    }

    /**
     * @dev Internal helper to handle gas payment
     * @param hubAddress The destination hub address (as string)
     * @param payload The data payload for the transaction.
     * @param gasValue Amount of native token to pay for gas
     */
    function _payGas(string memory hubAddress, bytes memory payload, uint256 gasValue) internal {
        // Gas for the ITS msg must be estimated off-chain
        bool estimateOnChain = false;
        // No need to set the gas limit since it's not being estimated on-chain
        uint256 executionGasLimit = 0;
        // solhint-disable-next-line avoid-tx-origin
        address refundAddress = tx.origin;
        bytes memory params = '';

        // slither-disable-next-line arbitrary-send-eth
        gasService.payGas{ value: gasValue }(
            address(this),
            ITS_HUB_CHAIN_NAME,
            hubAddress,
            payload,
            executionGasLimit,
            estimateOnChain,
            refundAddress,
            params
        );
    }

    function _execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes memory payload,
        bytes32 payloadHash
    ) internal {
        uint256 messageType;
        string memory originalSourceChain;
        (messageType, originalSourceChain, payload) = _decodeHubMessage(payload);

        if (messageType == MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            address expressExecutor = _getExpressExecutorAndEmitEvent(commandId, sourceChain, sourceAddress, payloadHash);
            _processInterchainTransferPayload(commandId, expressExecutor, originalSourceChain, payload);
        } else if (messageType == MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN) {
            _processDeployInterchainTokenPayload(payload);
        } else if (messageType == MESSAGE_TYPE_LINK_TOKEN) {
            _processLinkTokenPayload(originalSourceChain, payload);
        } else {
            revert InvalidMessageType(messageType);
        }
    }

    /**
     * @notice Uses the caller's tokens to fulfill the transfer before the message arrives. Use this only if you have detected an outgoing
     * interchainTransfer that matches the parameters passed here. The caller takes the risk of not receiving a refund if the source chain reorgs.
     * @param commandId The unique message id of the transfer being expressed.
     * @param sourceChain the name of the chain where the interchainTransfer originated from.
     * @param payload the payload of the receive token
     */
    function _expressExecute(bytes32 commandId, string memory sourceChain, bytes memory payload) internal {
        (, bytes32 tokenId, bytes memory sourceAddress, bytes memory destinationAddressBytes, uint256 amount, bytes memory data) = abi
            .decode(payload, (uint256, bytes32, bytes, bytes, uint256, bytes));
        address destinationAddress = destinationAddressBytes.toAddress();

        IERC20 token;
        {
            (bool success, bytes memory returnData) = tokenHandler.delegatecall(
                abi.encodeWithSelector(ITokenHandler.transferTokenFrom.selector, tokenId, msg.sender, destinationAddress, amount)
            );
            if (!success) revert TokenHandlerFailed(returnData);
            (amount, token) = abi.decode(returnData, (uint256, IERC20));
        }

        // slither-disable-next-line reentrancy-events
        emit InterchainTransferReceived(
            commandId,
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data.length == 0 ? bytes32(0) : keccak256(data)
        );

        if (data.length != 0) {
            bytes32 result = IInterchainTokenExpressExecutable(destinationAddress).expressExecuteWithInterchainToken(
                commandId,
                sourceChain,
                sourceAddress,
                data,
                tokenId,
                address(token),
                amount
            );

            if (result != EXPRESS_EXECUTE_SUCCESS) revert ExpressExecuteWithInterchainTokenFailed(destinationAddress);
        }
    }

    function _getMessageType(bytes memory payload) internal pure returns (uint256 messageType) {
        if (payload.length < 32) revert InvalidPayload();

        /// @solidity memory-safe-assembly
        assembly {
            messageType := mload(add(payload, 32))
        }
    }

    /**
     * @dev Return the parameters for the execute call, taking routing via ITS Hub into account.
     */
    function _decodeHubMessage(bytes memory payload) internal view returns (uint256, string memory, bytes memory) {
        // Read the first 32 bytes of the payload to determine the message type
        uint256 messageType = _getMessageType(payload);

        // Unwrap ITS message if coming from ITS hub
        if (messageType != MESSAGE_TYPE_RECEIVE_FROM_HUB) {
            revert InvalidMessageType(messageType);
        }

        // True source chain, this is found in the ITS Hub message.
        string memory originalSourceChain;

        (, originalSourceChain, payload) = abi.decode(payload, (uint256, string, bytes));

        // Check whether the original source chain is expected to be routed via the ITS Hub
        if (!isTrustedChain(originalSourceChain)) revert UntrustedChain();

        // Get message type of the inner ITS message
        messageType = _getMessageType(payload);

        return (messageType, originalSourceChain, payload);
    }

    /**
     * @notice Deploys an interchain token on a destination chain.
     * @param tokenId The ID of the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals of the token.
     * @param minter The minter address for the token.
     * @param destinationChain The destination chain where the token will be deployed.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _deployRemoteInterchainToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory minter,
        string calldata destinationChain,
        uint256 gasValue
    ) internal {
        if (bytes(name).length == 0) revert EmptyTokenName();
        if (bytes(symbol).length == 0) revert EmptyTokenSymbol();

        // slither-disable-next-line unused-return
        deployedTokenManager(tokenId);

        // slither-disable-next-line reentrancy-events
        emit InterchainTokenDeploymentStarted(tokenId, name, symbol, decimals, minter, destinationChain);

        bytes memory payload = abi.encode(MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, minter);

        _routeMessage(destinationChain, payload, gasValue);
    }

    /**
     * @notice Deploys a token manager.
     * @param tokenId The ID of the token.
     * @param tokenManagerType The type of the token manager to be deployed.
     * @param tokenAddress The address of the token to be managed.
     * @param operator The operator of the token manager.
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, address tokenAddress, bytes memory operator) internal {
        // TokenManagerProxy params
        bytes memory params = abi.encode(operator, tokenAddress);

        (bool success, bytes memory returnData) = tokenManagerDeployer.delegatecall(
            abi.encodeWithSelector(ITokenManagerDeployer.deployTokenManager.selector, tokenId, tokenManagerType, params)
        );
        if (!success) revert TokenManagerDeploymentFailed(returnData);

        address tokenManager_;
        assembly {
            tokenManager_ := mload(add(returnData, 0x20))
        }

        (success, returnData) = tokenHandler.delegatecall(
            abi.encodeWithSelector(ITokenHandler.postTokenManagerDeploy.selector, tokenManagerType, tokenManager_)
        );
        if (!success) revert PostDeployFailed(returnData);

        // slither-disable-next-line reentrancy-events
        emit TokenManagerDeployed(tokenId, tokenManager_, tokenManagerType, params);
    }

    /**
     * @notice Computes the salt for an interchain token deployment.
     * @param tokenId The ID of the token.
     * @return salt The computed salt for the token deployment.
     */
    function _getInterchainTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, tokenId));
    }

    /**
     * @notice Deploys an interchain token.
     * @param tokenId The ID of the token.
     * @param minterBytes The minter address for the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals of the token.
     */
    function _deployInterchainToken(
        bytes32 tokenId,
        bytes memory minterBytes,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (address tokenAddress) {
        if (bytes(name).length == 0) revert EmptyTokenName();
        if (bytes(symbol).length == 0) revert EmptyTokenSymbol();

        bytes32 salt = _getInterchainTokenSalt(tokenId);

        address minter;
        if (bytes(minterBytes).length != 0) minter = minterBytes.toAddress();

        (bool success, bytes memory returnData) = interchainTokenDeployer.delegatecall(
            abi.encodeWithSelector(IInterchainTokenDeployer.deployInterchainToken.selector, salt, tokenId, minter, name, symbol, decimals)
        );
        if (!success) {
            revert InterchainTokenDeploymentFailed(returnData);
        }

        assembly {
            tokenAddress := mload(add(returnData, 0x20))
        }

        // slither-disable-next-line reentrancy-events
        emit InterchainTokenDeployed(tokenId, tokenAddress, minter, name, symbol, decimals);
    }

    /**
     * @notice Decodes the metadata into a version number and data bytes.
     * @dev The function expects the metadata to have the version in the first 4 bytes, followed by the actual data.
     * @param metadata The bytes containing the metadata to decode.
     * @return data The data bytes extracted from the metadata.
     */
    function _decodeMetadata(bytes calldata metadata) internal pure returns (bytes memory data) {
        if (metadata.length < 4) return data;

        uint32 versionUint = uint32(bytes4(metadata[:4]));
        // This check is maintained for backward compatibility with existing integrations
        // that expect a specific metadata format with METADATA_CONTRACT_CALL version
        if (versionUint != METADATA_CONTRACT_CALL) revert InvalidMetadataVersion(versionUint);

        if (metadata.length == 4) return data;
        data = metadata[4:];
    }

    /**
     * @dev Performs an interchain transfer from `msg.sender` to the address on the destination chain.
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The contract address on the destination chain to send the tokens to and execute.
     * @param amount The amount of tokens to be transferred.
     * @param data Additional data to be provided to the destination contract when executed along with the token transfer.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes memory data,
        uint256 gasValue
    ) internal {
        amount = _takeToken(tokenId, msg.sender, amount, false);

        _transmitInterchainTransfer(tokenId, msg.sender, destinationChain, destinationAddress, amount, data, gasValue);
    }

    /**
     * @notice Transmit a callContractWithInterchainToken for the given tokenId.
     * @param tokenId The tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress The address where the token is coming from, which will also be used for gas reimbursement.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of tokens to send.
     * @param data The data to be passed with the token transfer.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes memory data,
        uint256 gasValue
    ) internal {
        if (destinationAddress.length == 0) revert EmptyDestinationAddress();
        if (amount == 0) revert ZeroAmount();

        // slither-disable-next-line reentrancy-events
        emit InterchainTransfer(
            tokenId,
            sourceAddress,
            destinationChain,
            destinationAddress,
            amount,
            data.length == 0 ? bytes32(0) : keccak256(data)
        );

        bytes memory payload = abi.encode(
            MESSAGE_TYPE_INTERCHAIN_TRANSFER,
            tokenId,
            sourceAddress.toBytes(),
            destinationAddress,
            amount,
            data
        );

        _routeMessage(destinationChain, payload, gasValue);
    }

    /**
     * @dev Takes token from a sender via the token service. `tokenOnly` indicates if the caller should be restricted to the token only.
     */
    function _takeToken(bytes32 tokenId, address from, uint256 amount, bool tokenOnly) internal returns (uint256) {
        (bool success, bytes memory data) = tokenHandler.delegatecall(
            abi.encodeWithSelector(ITokenHandler.takeToken.selector, tokenId, tokenOnly, from, amount)
        );
        if (!success) revert TakeTokenFailed(data);
        amount = abi.decode(data, (uint256));

        return amount;
    }

    /**
     * @dev Gives token to recipient via the token service.
     */
    function _giveToken(bytes32 tokenId, address to, uint256 amount) internal returns (uint256, address tokenAddress) {
        (bool success, bytes memory data) = tokenHandler.delegatecall(
            abi.encodeWithSelector(ITokenHandler.giveToken.selector, tokenId, to, amount)
        );
        if (!success) revert GiveTokenFailed(data);
        (amount, tokenAddress) = abi.decode(data, (uint256, address));

        return (amount, tokenAddress);
    }

    /**
     * @notice Returns the amount of token that this call is worth.
     * @dev If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address.
     * @param payload The payload sent with the call.
     * @return address The token address.
     * @return uint256 The value the call is worth.
     */
    function _contractCallValue(bytes memory payload) internal view returns (address, uint256) {
        uint256 messageType;
        (messageType, , payload) = _decodeHubMessage(payload);

        if (messageType != MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            revert InvalidExpressMessageType(messageType);
        }

        bytes32 tokenId;
        uint256 amount;
        (, tokenId, , , amount) = abi.decode(payload, (uint256, bytes32, bytes, bytes, uint256));

        return (registeredTokenAddress(tokenId), amount);
    }

    function _getExpressExecutorAndEmitEvent(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal returns (address expressExecutor) {
        expressExecutor = _popExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash);

        if (expressExecutor != address(0)) {
            emit ExpressExecutionFulfilled(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);
        }
    }
}
