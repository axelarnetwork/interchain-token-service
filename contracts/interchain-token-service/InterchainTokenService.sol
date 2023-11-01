// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Address } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Address.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/Bytes32String.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';
import { IRemoteAddressValidator } from '../interfaces/IRemoteAddressValidator.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ExpressCallHandler } from '../utils/ExpressCallHandler.sol';
import { Pausable } from '../utils/Pausable.sol';
import { Operatable } from '../utils/Operatable.sol';
import { Multicall } from '../utils/Multicall.sol';

/**
 * @title Interchain Token Service
 * @notice This contract is responsible for facilitating cross chain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.
 * @dev The only storage used here is for ExpressCalls.
 */
contract InterchainTokenService is
    IInterchainTokenService,
    Upgradable,
    Operatable,
    ExpressCallHandler,
    Pausable,
    Multicall,
    Create3Address
{
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;
    using SafeTokenTransferFrom for IERC20;

    address internal immutable implementationLockUnlock;
    address internal immutable implementationMintBurn;
    address internal immutable implementationMintBurnFrom;
    address internal immutable implementationLockUnlockFee;
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;
    IRemoteAddressValidator public immutable remoteAddressValidator;
    address public immutable tokenManagerDeployer;
    address public immutable standardizedTokenDeployer;
    bytes32 public immutable chainNameHash;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('its-custom-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_ID = keccak256('its-standardized-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_SALT = keccak256('its-standardized-token-salt');

    uint256 private constant SELECTOR_RECEIVE_TOKEN = 1;
    uint256 private constant SELECTOR_RECEIVE_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
    uint256 private constant SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');

    /**
     * @notice Constructor for the Interchain Token Service
     * @dev All of the variables passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ The address of the TokenManagerDeployer.
     * @param standardizedTokenDeployer_ The address of the StandardizedTokenDeployer.
     * @param gateway_ The address of the AxelarGateway.
     * @param gasService_ The address of the AxelarGasService.
     * @param remoteAddressValidator_ The address of the RemoteAddressValidator.
     * @param tokenManagerImplementations The tokenManager implementations in the order: Mint-burn, Mint-burn from, Lock-unlock, and Lock-unlock with fee.
     */
    constructor(
        address tokenManagerDeployer_,
        address standardizedTokenDeployer_,
        address gateway_,
        address gasService_,
        address remoteAddressValidator_,
        address[] memory tokenManagerImplementations
    ) {
        if (
            remoteAddressValidator_ == address(0) ||
            gasService_ == address(0) ||
            tokenManagerDeployer_ == address(0) ||
            standardizedTokenDeployer_ == address(0) ||
            gateway_ == address(0)
        ) revert ZeroAddress();

        gateway = IAxelarGateway(gateway_);
        remoteAddressValidator = IRemoteAddressValidator(remoteAddressValidator_);
        gasService = IAxelarGasService(gasService_);
        tokenManagerDeployer = tokenManagerDeployer_;
        standardizedTokenDeployer = standardizedTokenDeployer_;

        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        implementationMintBurn = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN);
        implementationMintBurnFrom = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN_FROM);
        implementationLockUnlock = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK);
        implementationLockUnlockFee = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK_FEE);
        string memory chainName_ = remoteAddressValidator.chainName();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /*******\
    MODIFIERS
    \*******/

    /**
     * @notice This modifier is used to ensure that only a remote InterchainTokenService can invoke the execute function.
     * @param sourceChain The source chain of the contract call.
     * @param sourceAddress The source address that the call came from.
     */
    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!remoteAddressValidator.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    /**
     * @notice This modifier is used to ensure certain functions can only be called by TokenManagers.
     * @param tokenId The `tokenId` of the TokenManager trying to perform the call.
     */
    modifier onlyTokenManager(bytes32 tokenId) {
        if (msg.sender != getTokenManagerAddress(tokenId)) revert NotTokenManager();
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
     * @return tokenManagerAddress The deployment address of the TokenManager.
     */
    function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = _create3Address(tokenId);
    }

    /**
     * @notice Returns the address of a TokenManager from a specific tokenId.
     * @dev The TokenManager needs to exist already.
     * @param tokenId The tokenId.
     * @return tokenManagerAddress The deployment address of the TokenManager.
     */
    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if (tokenManagerAddress.code.length == 0) revert TokenManagerDoesNotExist(tokenId);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId The tokenId.
     * @return tokenAddress The address of the token.
     */
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        address tokenManagerAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenManagerAddress).tokenAddress();
    }

    /**
     * @notice Returns the address of the standardized token that would be deployed with a given tokenId.
     * @dev The token does not need to exist.
     * @param tokenId The tokenId.
     * @return tokenAddress The address of the standardized token.
     */
    function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenId = _getStandardizedTokenSalt(tokenId);
        tokenAddress = _create3Address(tokenId);
    }

    /**
     * @notice Calculates the tokenId that would correspond to a canonical link for a given token.
     * @dev The tokenId will depend on what chain it is called from, unlike custom tokenIds.
     * @param tokenAddress The address of the token.
     * @return tokenId The tokenId that the canonical TokenManager would get (or has gotten) for the token.
     */
    function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_ID, chainNameHash, tokenAddress));
    }

    /**
     * @notice Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
     * @dev The tokenId will not depend on what chain it is called from, unlike canonical tokenIds.
     * @param sender The address of the TokenManager deployer.
     * @param salt The salt that the deployer uses for the deployment.
     * @return tokenId The tokenId that the custom TokenManager would get (or has gotten).
     */
    function getCustomTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, sender, salt));
    }

    /**
     * @notice Getter function for TokenManager implementations. This will mainly be called by TokenManager proxies
     * to figure out their implementations.
     * @param tokenManagerType The type of the TokenManager.
     * @return tokenManagerAddress The address of the TokenManager implementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address) {
        if (tokenManagerType > uint256(type(TokenManagerType).max)) revert InvalidImplementation();

        if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) return implementationMintBurn;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN_FROM) return implementationMintBurnFrom;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) return implementationLockUnlock;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK_FEE) return implementationLockUnlockFee;

        revert InvalidImplementation();
    }

    /**
     * @notice Getter function for the flow limit of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowLimit The flow limit.
     */
    function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowLimit = tokenManager.getFlowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowOutAmount The flow out amount.
     */
    function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowOutAmount = tokenManager.getFlowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowInAmount The flow in amount.
     */
    function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowInAmount = tokenManager.getFlowInAmount();
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Used to register canonical tokens.
     * @dev The caller does not matter.
     * @param tokenAddress The token to be bridged.
     * @return tokenId The tokenId that was used for this canonical token.
     */
    function registerCanonicalToken(address tokenAddress) external payable notPaused returns (bytes32 tokenId) {
        (, string memory tokenSymbol, ) = _validateToken(tokenAddress);
        if (gateway.tokenAddresses(tokenSymbol) == tokenAddress) revert GatewayToken();
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode('', tokenAddress));
    }

    /**
     * @notice Used to deploy remote TokenManagers and standardized tokens for a canonical token.
     * @dev This function must be called from the chain where the canonical token was registered, but may be called by anyone.
     * At least the `gasValue` amount specified must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls.
     * @param tokenId The tokenId of the canonical token.
     * @param destinationChain The name of the chain to deploy the TokenManager and standardized token to.
     * @param gasValue The amount of native tokens to be used to pay for gas for the remote deployment.
     */
    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) public payable notPaused {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();

        if (getCanonicalTokenId(tokenAddress) != tokenId) revert NotCanonicalTokenManager();

        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        _deployRemoteStandardizedToken(tokenId, tokenName, tokenSymbol, tokenDecimals, '', '', 0, '', destinationChain, gasValue);
    }

    /**
     * @notice Used to deploy custom TokenManagers with the specified salt.
     * @dev Different callers would result in different tokenIds.
     * @param salt The salt to be used during deployment.
     * @param tokenManagerType The type of TokenManager to be deployed.
     * @param params The params that will be used to initialize the TokenManager.
     * @return tokenId The tokenId corresponding to the deployed TokenManager.
     */
    function deployCustomTokenManager(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) public payable notPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = getCustomTokenId(deployer_, salt);

        emit CustomTokenIdClaimed(tokenId, deployer_, salt);

        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    /**
     * @notice Used to deploy remote custom TokenManagers.
     * @dev At least the `gasValue` amount specified must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls.
     * @param salt The salt to be used during deployment.
     * @param destinationChain The name of the chain to deploy the TokenManager and standardized token to.
     * @param tokenManagerType The type of TokenManager to be deployed.
     * @param params The params that will be used to initialize the TokenManager.
     * @param gasValue The amount of native tokens to be used to pay for gas for the remote deployment.
     * @return tokenId The tokenId corresponding to the deployed remote TokenManager.
     */
    function deployRemoteCustomTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable notPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = getCustomTokenId(deployer_, salt);

        emit CustomTokenIdClaimed(tokenId, deployer_, salt);

        _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager.
     * @param salt The salt to be used during deployment.
     * @param name The name of the token to be deployed.
     * @param symbol The symbol of the token to be deployed.
     * @param decimals The decimals of the token to be deployed.
     * @param mintAmount The amount of token to be minted to msg.sender during deployment.
     * @param distributor The address that will be able to mint and burn the deployed token.
     */
    function deployAndRegisterStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, mintAmount, msg.sender);
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(msg.sender.toBytes(), tokenAddress));
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager in another chain.
     * @dev At least the `gasValue` amount specified must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls. If the `distributor` parameter is empty bytes then
     * a mint/burn TokenManager is used, otherwise a lock/unlock TokenManager is used.
     * @param salt The salt to be used during deployment.
     * @param name The name of the token to be deployed.
     * @param symbol The symbol of the token to be deployed.
     * @param decimals The decimals of the token to be deployed.
     * @param distributor The address that will be able to mint and burn the deployed token.
     * @param mintTo The address where the minted tokens will be sent upon deployment.
     * @param mintAmount The amount of tokens to be minted upon deployment.
     * @param operator_ The operator data for standardized tokens.
     * @param destinationChain The name of the destination chain to deploy to.
     * @param gasValue The amount of native tokens to be used to pay for gas for the remote deployment.
     */
    function deployAndRegisterRemoteStandardizedToken(
        bytes32 salt,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory mintTo,
        uint256 mintAmount,
        bytes memory operator_,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteStandardizedToken(
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            mintTo,
            mintAmount,
            operator_,
            destinationChain,
            gasValue
        );
    }

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time.
     * @dev This function should only be invoked once an outgoing interchainTransfer that matches the parameters passed here has been detected.
     * This is not to be used with fee-on-transfer tokens as it will incur losses for the express caller.
     * @param payload The payload of the receive token.
     * @param commandId The sendHash detected at the sourceChain.
     * @param sourceChain The source chain of the receive token.
     */
    function expressReceiveToken(bytes calldata payload, bytes32 commandId, string calldata sourceChain) external {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted(commandId);

        address caller = msg.sender;
        _setExpressReceiveToken(payload, commandId, caller);

        (uint256 selector, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount) = abi.decode(
            payload,
            (uint256, bytes32, bytes, uint256)
        );
        address destinationAddress = destinationAddressBytes.toAddress();

        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());

        token.safeTransferFrom(caller, destinationAddress, amount);

        if (selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            (, , , , bytes memory sourceAddress, bytes memory data) = abi.decode(payload, (uint256, bytes32, bytes, uint256, bytes, bytes));
            IInterchainTokenExpressExecutable(destinationAddress).expressExecuteWithInterchainToken(
                sourceChain,
                sourceAddress,
                data,
                tokenId,
                address(token),
                amount
            );
        } else if (selector != SELECTOR_RECEIVE_TOKEN) {
            revert InvalidExpressSelector();
        }
    }

    /**
     * @notice Initiates an interchain transfer of a specified token to a destination chain.
     * @dev The function retrieves the TokenManager associated with the tokenId.
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The address on the destination chain to send the tokens to.
     * @param amount The amount of tokens to be transferred.
     * @param metadata Additional data to be passed along with the transfer.
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external {
        ITokenManager tokenManager = ITokenManager(getTokenManagerAddress(tokenId));
        amount = tokenManager.takeToken(msg.sender, amount);
        _transmitSendToken(tokenId, msg.sender, destinationChain, destinationAddress, amount, metadata);
    }

    /**
     * @notice Sends tokens to a specified address on a destination chain along with additional data.
     * @dev The function retrieves the TokenManager associated with the tokenId.
     * @param tokenId The unique identifier of the token to be sent.
     * @param destinationChain The destination chain where the tokens will be sent.
     * @param destinationAddress The address on the destination chain where the tokens will be sent.
     * @param amount The amount of tokens to be sent.
     * @param data Additional data to be sent along with the tokens.
     */
    function sendTokenWithData(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external {
        ITokenManager tokenManager = ITokenManager(getTokenManagerAddress(tokenId));
        amount = tokenManager.takeToken(msg.sender, amount);
        uint32 prefix = 0;
        _transmitSendToken(tokenId, msg.sender, destinationChain, destinationAddress, amount, abi.encodePacked(prefix, data));
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    /**
     * @notice Transmit a sendTokenWithData for the given tokenId.
     * @dev Only callable by a token manager.
     * @param tokenId The tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress The source address where the token is coming from, which will also be used for gas reimbursement.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of tokens to send.
     * @param metadata The data to be sent with the call.
     */
    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable onlyTokenManager(tokenId) notPaused {
        _transmitSendToken(tokenId, sourceAddress, destinationChain, destinationAddress, amount, metadata);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds An array of the tokenIds of the tokenManagers to set the flow limits of.
     * @param flowLimits The flowLimits to set.
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyOperator {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenIds[i]));
            // slither-disable-next-line calls-loop
            tokenManager.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to pause the entire service.
     * @param paused Boolean value representing the pause state of the service.
     */
    function setPaused(bool paused) external onlyOwner {
        _setPaused(paused);
    }

    /****************\
    INTERNAL FUNCTIONS
    \****************/

    function _setup(bytes calldata params) internal override {
        _setOperator(params.toAddress());
    }

    /**
     * @notice Sanitizes and validates the token manager implementation by checking that the provided implementation
     * address is not zero, and that the type of the token manager implementation matches the expected `tokenManagerType`.
     * @param tokenManagerImplementations An array containing addresses of different token manager implementations.
     * @param tokenManagerType The expected type of the token manager implementation.
     * @return implementation_ The validated address of the token manager implementation.
     */
    function _sanitizeTokenManagerImplementation(
        address[] memory tokenManagerImplementations,
        TokenManagerType tokenManagerType
    ) internal pure returns (address implementation_) {
        implementation_ = tokenManagerImplementations[uint256(tokenManagerType)];
        if (implementation_ == address(0)) revert ZeroAddress();
        if (ITokenManager(implementation_).implementationType() != uint256(tokenManagerType)) revert InvalidTokenManagerImplementation();
    }

    /**
     * @notice Executes operations based on the payload and selector.
     * @param commandId The AxelarGateway command ID
     * @param sourceChain The chain where the transaction originates from.
     * @param sourceAddress The address where the transaction originates from.
     * @param payload The encoded data payload for the transaction.
     */
    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external onlyRemoteService(sourceChain, sourceAddress) notPaused {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();

        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SELECTOR_RECEIVE_TOKEN || selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA)
            return _processReceiveTokenPayload(commandId, sourceChain, payload, selector);
        if (selector == SELECTOR_DEPLOY_TOKEN_MANAGER) return _processDeployTokenManagerPayload(payload);
        if (selector == SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN) return _processDeployStandardizedTokenAndManagerPayload(payload);

        revert SelectorUnknown();
    }

    function executeWithToken(
        bytes32 /*commandId*/,
        string calldata /*sourceChain*/,
        string calldata /*sourceAddress*/,
        bytes calldata /*payload*/,
        string calldata /*tokenSymbol*/,
        uint256 /*amount*/
    ) external pure {
        revert ExecuteWithTokenNotSupported();
    }

    /**
     * @notice Processes the payload data for a send token call.
     * @param commandId The AxelarGateway command ID.
     * @param sourceChain The chain where the transaction originates from.
     * @param payload The encoded data payload to be processed.
     * @param selector The selector specifying what action the service must perform.
     */
    function _processReceiveTokenPayload(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata payload,
        uint256 selector
    ) internal {
        bytes32 tokenId;
        address destinationAddress;
        uint256 amount;
        {
            bytes memory destinationAddressBytes;
            (, tokenId, destinationAddressBytes, amount) = abi.decode(payload, (uint256, bytes32, bytes, uint256));
            destinationAddress = destinationAddressBytes.toAddress();
        }

        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        {
            address expressCaller = _popExpressReceiveToken(payload, commandId);
            if (expressCaller != address(0)) {
                amount = tokenManager.giveToken(expressCaller, amount);
                return;
            }
        }
        amount = tokenManager.giveToken(destinationAddress, amount);

        if (selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            bytes memory sourceAddress;
            bytes memory data;
            (, , , , sourceAddress, data) = abi.decode(payload, (uint256, bytes32, bytes, uint256, bytes, bytes));

            // slither-disable-next-line reentrancy-events
            emit TokenReceivedWithData(tokenId, sourceChain, destinationAddress, amount, sourceAddress, data);

            IInterchainTokenExecutable(destinationAddress).executeWithInterchainToken(
                sourceChain,
                sourceAddress,
                data,
                tokenId,
                tokenManager.tokenAddress(),
                amount
            );
        } else {
            // slither-disable-next-line reentrancy-events
            emit TokenReceived(tokenId, sourceChain, destinationAddress, amount);
        }
    }

    /**
     * @notice Processes a deploy token manager payload.
     * @param payload The encoded data payload to be processed.
     */
    function _processDeployTokenManagerPayload(bytes calldata payload) internal {
        (, bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) = abi.decode(
            payload,
            (uint256, bytes32, TokenManagerType, bytes)
        );

        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    /**
     * @notice Process a deploy standardized token and manager payload.
     * @param payload The encoded data payload to be processed.
     */
    function _processDeployStandardizedTokenAndManagerPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenId,
            string memory name,
            string memory symbol,
            uint8 decimals,
            bytes memory distributorBytes,
            bytes memory mintToBytes,
            uint256 mintAmount,
            bytes memory operatorBytes
        ) = abi.decode(payload, (uint256, bytes32, string, string, uint8, bytes, bytes, uint256, bytes));
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        address distributor;
        address mintTo;

        if (distributorBytes.length == 0) {
            distributor = tokenManagerAddress;
        } else {
            distributor = distributorBytes.toAddress();
        }

        if (mintToBytes.length == 0) {
            mintTo = distributor;
        } else {
            mintTo = mintToBytes.toAddress();
        }

        if (operatorBytes.length == 0) {
            operatorBytes = address(this).toBytes();
        }

        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, mintAmount, mintTo);
        _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(operatorBytes, tokenAddress));
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _callContract(string calldata destinationChain, bytes memory payload, uint256 gasValue) internal {
        string memory destinationAddress = remoteAddressValidator.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload, // solhint-disable-next-line avoid-tx-origin
                tx.origin
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @dev Validates and retrieves the basic information of an ERC20 token.
     * @param tokenAddress The address of the token to validate and retrieve information from.
     * @return name The name of the token.
     * @return symbol The symbol of the token.
     * @return decimals The number of decimals the token uses.
     */
    function _validateToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    /**
     * @notice Deploys a token manager on a destination chain.
     * @param tokenId The ID of the token.
     * @param destinationChain The chain where the token manager will be deployed.
     * @param gasValue The amount of gas to be paid for the transaction.
     * @param tokenManagerType The type of token manager to be deployed.
     * @param params Additional parameters for the token manager deployment.
     */
    function _deployRemoteTokenManager(
        bytes32 tokenId,
        string calldata destinationChain,
        uint256 gasValue,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) internal {
        emit RemoteTokenManagerDeploymentInitialized(tokenId, destinationChain, gasValue, tokenManagerType, params);

        bytes memory payload = abi.encode(SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, tokenManagerType, params);
        _callContract(destinationChain, payload, gasValue);
    }

    /**
     * @notice Deploys a standardized token on a destination chain.
     * @param tokenId The ID of the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals of the token.
     * @param distributor The distributor address for the token.
     * @param mintTo The address where the minted tokens will be sent upon deployment.
     * @param mintAmount The amount of tokens to be minted upon deployment.
     * @param operator_ The operator data for standardized tokens.
     * @param destinationChain The destination chain where the token will be deployed.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _deployRemoteStandardizedToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory mintTo,
        uint256 mintAmount,
        bytes memory operator_,
        string calldata destinationChain,
        uint256 gasValue
    ) internal {
        // slither-disable-next-line reentrancy-events
        emit RemoteStandardizedTokenAndManagerDeploymentInitialized(
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            mintTo,
            mintAmount,
            operator_,
            destinationChain,
            gasValue
        );

        bytes memory payload = abi.encode(
            SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            mintTo,
            mintAmount,
            operator_
        );
        _callContract(destinationChain, payload, gasValue);
    }

    /**
     * @notice Deploys a token manager.
     * @param tokenId The ID of the token.
     * @param tokenManagerType The type of the token manager to be deployed.
     * @param params Additional parameters for the token manager deployment.
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) internal {
        // slither-disable-next-line reentrancy-events
        emit TokenManagerDeployed(tokenId, tokenManagerType, params);

        // slither-disable-next-line controlled-delegatecall
        (bool success, ) = tokenManagerDeployer.delegatecall(
            abi.encodeWithSelector(ITokenManagerDeployer.deployTokenManager.selector, tokenId, tokenManagerType, params)
        );
        if (!success) revert TokenManagerDeploymentFailed();
    }

    /**
     * @notice Computes the salt for a standardized token deployment.
     * @param tokenId The ID of the token.
     * @return salt The computed salt for the token deployment.
     */
    function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        return keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_SALT, tokenId));
    }

    /**
     * @notice Deploys a standardized token.
     * @param tokenId The ID of the token.
     * @param distributor The distributor address for the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals of the token.
     * @param mintAmount The amount of tokens to be minted upon deployment.
     * @param mintTo The address where the minted tokens will be sent upon deployment.
     */
    function _deployStandardizedToken(
        bytes32 tokenId,
        address distributor,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) internal {
        emit StandardizedTokenDeployed(tokenId, distributor, name, symbol, decimals, mintAmount, mintTo);

        bytes32 salt = _getStandardizedTokenSalt(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);

        // slither-disable-next-line controlled-delegatecall
        (bool success, ) = standardizedTokenDeployer.delegatecall(
            abi.encodeWithSelector(
                IStandardizedTokenDeployer.deployStandardizedToken.selector,
                salt,
                tokenManagerAddress,
                distributor,
                name,
                symbol,
                decimals,
                mintAmount,
                mintTo
            )
        );
        if (!success) {
            revert StandardizedTokenDeploymentFailed();
        }
    }

    /**
     * @notice Decodes the metadata into a version number and data bytes.
     * @dev The function expects the metadata to have the version in the first 4 bytes, followed by the actual data.
     * @param metadata The bytes containing the metadata to decode.
     * @return version The version number extracted from the metadata.
     * @return data The data bytes extracted from the metadata.
     */
    function _decodeMetadata(bytes memory metadata) internal pure returns (uint32 version, bytes memory data) {
        data = new bytes(metadata.length - 4);
        assembly {
            version := shr(224, mload(add(metadata, 32)))
        }
        if (data.length == 0) return (version, data);
        uint256 n = (data.length - 1) / 32;
        for (uint256 i = 0; i <= n; ++i) {
            assembly {
                mstore(add(data, add(32, mul(32, i))), mload(add(metadata, add(36, mul(32, i)))))
            }
        }
    }

    /**
     * @notice Transmit a sendTokenWithData for the given tokenId.
     * @dev Only callable by a token manager.
     * @param tokenId The tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress The address where the token is coming from, which will also be used for gas reimbursement.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of tokens to send.
     * @param metadata The data to be passed with the token transfer.
     */
    function _transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes memory metadata
    ) internal {
        bytes memory payload;
        if (metadata.length < 4) {
            // slither-disable-next-line reentrancy-events
            emit TokenSent(tokenId, destinationChain, destinationAddress, amount);

            payload = abi.encode(SELECTOR_RECEIVE_TOKEN, tokenId, destinationAddress, amount);

            _callContract(destinationChain, payload, msg.value);
            return;
        }
        uint32 version;
        (version, metadata) = _decodeMetadata(metadata);
        if (version > 0) revert InvalidMetadataVersion(version);

        // slither-disable-next-line reentrancy-events
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, metadata);

        payload = abi.encode(SELECTOR_RECEIVE_TOKEN_WITH_DATA, tokenId, destinationAddress, amount, sourceAddress.toBytes(), metadata);

        _callContract(destinationChain, payload, msg.value);
    }
}
