// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ExpressCallHandler } from '../utils/ExpressCallHandler.sol';
import { Pausable } from '../utils/Pausable.sol';
import { Operatable } from '../utils/Operatable.sol';
import { Multicall } from '../utils/Multicall.sol';

/**
 * @title The Interchain Token Service
 * @notice This contract is responsible for facilitating cross chain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.
 * @dev The only storage used here is for ExpressCalls
 */
contract InterchainTokenService is
    IInterchainTokenService,
    AxelarExecutable,
    Upgradable,
    Operatable,
    ExpressCallHandler,
    Pausable,
    Multicall
{
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;

    address internal immutable implementationLockUnlock;
    address internal immutable implementationMintBurn;
    address internal immutable implementationLiquidityPool;
    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    address public immutable tokenManagerDeployer;
    address public immutable standardizedTokenDeployer;
    Create3Deployer internal immutable deployer;
    bytes32 internal immutable chainNameHash;
    bytes32 internal immutable chainName;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('its-custom-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_ID = keccak256('its-standardized-token-id');
    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_SALT = keccak256('its-standardized-token-salt');

    uint256 private constant SELECTOR_SEND_TOKEN = 1;
    uint256 private constant SELECTOR_SEND_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
    uint256 private constant SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

    // keccak256('interchain-token-service')
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    /**
     * @dev All of the varaibles passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ the address of the TokenManagerDeployer.
     * @param standardizedTokenDeployer_ the address of the StandardizedTokenDeployer.
     * @param gateway_ the address of the AxelarGateway.
     * @param gasService_ the address of the AxelarGasService.
     * @param linkerRouter_ the address of the LinkerRouter.
     * @param tokenManagerImplementations this need to have exactly 3 implementations in the following order: Lock/Unlock, mint/burn and then liquidity pool.
     * @param chainName_ the name of the current chain.
     */
    constructor(
        address tokenManagerDeployer_,
        address standardizedTokenDeployer_,
        address gateway_,
        address gasService_,
        address linkerRouter_,
        address[] memory tokenManagerImplementations,
        string memory chainName_
    ) AxelarExecutable(gateway_) {
        if (
            linkerRouter_ == address(0) ||
            gasService_ == address(0) ||
            tokenManagerDeployer_ == address(0) ||
            standardizedTokenDeployer_ == address(0)
        ) revert ZeroAddress();
        linkerRouter = ILinkerRouter(linkerRouter_);
        gasService = IAxelarGasService(gasService_);
        tokenManagerDeployer = tokenManagerDeployer_;
        standardizedTokenDeployer = standardizedTokenDeployer_;
        deployer = ITokenManagerDeployer(tokenManagerDeployer_).deployer();

        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        implementationLockUnlock = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK);
        implementationMintBurn = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN);
        implementationLiquidityPool = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LIQUIDITY_POOL);

        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /*******\
    MODIFIERS
    \*******/

    /**
     * @notice This modifier is used to ensure that only a remote InterchainTokenService can _execute this one.
     * @param sourceChain the source of the contract call.
     * @param sourceAddress the address that the call came from.
     */
    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    /**
     * @notice This modifier is used to ensure certain functions can only be called by TokenManagers.
     * @param tokenId the `tokenId` of the TokenManager trying to perform the call.
     */
    modifier onlyTokenManager(bytes32 tokenId) {
        if (msg.sender != getTokenManagerAddress(tokenId)) revert NotTokenManager();
        _;
    }

    /*****\
    GETTERS
    \*****/

    /**
     * @notice Getter for the chain name.
     * @return name the name of the chain
     */
    function getChainName() public view returns (string memory name) {
        name = chainName.toTrimmedString();
    }

    /**
     * @notice Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress deployement address of the TokenManager.
     */
    function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /**
     * @notice Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress deployment address of the TokenManager.
     */
    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if (ITokenManagerProxy(tokenManagerAddress).tokenId() != tokenId) revert TokenManagerDoesNotExist(tokenId);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId the tokenId.
     * @return tokenAddress the address of the token.
     */
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        address tokenManagerAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenManagerAddress).tokenAddress();
    }

    /**
     * @notice Returns the address of the standardized token that would be deployed with a given tokenId.
     * The token does not need to exist.
     * @param tokenId the tokenId.
     * @return tokenAddress the address of the standardized token.
     */
    function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenId = _getStandardizedTokenSalt(tokenId);
        tokenAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /**
     * @notice Calculates the tokenId that would correspond to a canonical link for a given token.
     * This will depend on what chain it is called from, unlike custom tokenIds.
     * @param tokenAddress the address of the token.
     * @return tokenId the tokenId that the canonical TokenManager would get (or has gotten) for the token.
     */
    function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_ID, chainNameHash, tokenAddress));
    }

    /**
     * @notice Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
     * This will not depend on what chain it is called from, unlike canonical tokenIds.
     * @param sender the address of the TokenManager deployer.
     * @param salt the salt that the deployer uses for the deployment.
     * @return tokenId the tokenId that the custom TokenManager would get (or has gotten).
     */
    function getCustomTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, sender, salt));
    }

    /**
     * @notice Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
     * to figure out their implementations
     * @param tokenManagerType the type of the TokenManager.
     * @return tokenManagerAddress the address of the TokenManagerImplementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress) {
        // There could be a way to rewrite the following using assembly switch statements, which would be more gas efficient,
        // but accessing immutable variables and/or enum values seems to be tricky, and would reduce code readability.
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.LIQUIDITY_POOL) {
            return implementationLiquidityPool;
        }
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLockUnlock(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsMintBurn(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @param liquidityPoolAddress the liquidity pool to be used to store the bridged tokens.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress, liquidityPoolAddress);
    }

    /**
     * @notice Getter function for the flow limit of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowLimit the flow limit.
     */
    function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowLimit = tokenManager.getFlowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowOutAmount the flow out amount.
     */
    function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowOutAmount = tokenManager.getFlowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowInAmount the flow in amount.
     */
    function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount) {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        flowInAmount = tokenManager.getFlowInAmount();
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Used to register canonical tokens. Caller does not matter.
     * @param tokenAddress the token to be bridged.
     * @return tokenId the tokenId that was used for this canonical token.
     */
    function registerCanonicalToken(address tokenAddress) external payable notPaused returns (bytes32 tokenId) {
        (, string memory tokenSymbol, ) = _validateToken(tokenAddress);
        if (gateway.tokenAddresses(tokenSymbol) == tokenAddress) revert GatewayToken();
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this).toBytes(), tokenAddress));
    }

    /**
     * @notice Used to deploy remote TokenManagers and standardized tokens for a canonical token. This needs to be
     * called from the chain that registered the canonical token, and anyone can call it.
     * @param tokenId the tokenId of the canonical token.
     * @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment.
     * At least the amount specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
     */
    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) public payable notPaused {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();
        if (getCanonicalTokenId(tokenAddress) != tokenId) revert NotCanonicalTokenManager();
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        _deployRemoteStandardizedToken(tokenId, tokenName, tokenSymbol, tokenDecimals, '', '', destinationChain, gasValue);
    }

    /**
     * @notice Used to deploy custom TokenManagers with the specified salt. Different callers would result in different tokenIds.
     * @param salt the salt to be used.
     * @param tokenManagerType the type of TokenManager to be deployed.
     * @param params the params that will be used to initialize the TokenManager.
     */
    function deployCustomTokenManager(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) public payable notPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = getCustomTokenId(deployer_, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
        emit CustomTokenIdClaimed(tokenId, deployer_, salt);
    }

    /**
     * @notice Used to deploy remote custom TokenManagers.
     * @param salt the salt to be used.
     * @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
     * @param tokenManagerType the type of TokenManager to be deployed.
     * @param params the params that will be used to initialize the TokenManager.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least
     * the amount specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions
     * that could make remote contract calls.
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
        _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
        emit CustomTokenIdClaimed(tokenId, deployer_, salt);
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager. If the `distributor` is the address of the TokenManager (which
     * can be calculated ahead of time) then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
     * @param salt the salt to be used.
     * @param name the name of the token to be deployed.
     * @param symbol the symbol of the token to be deployed.
     * @param decimals the decimals of the token to be deployed.
     * @param mintAmount the amount of token to be mint during deployment to msg.sender.
     * @param distributor the address that will be able to mint and burn the deployed token.
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
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        TokenManagerType tokenManagerType = distributor == tokenManagerAddress ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        _deployTokenManager(tokenId, tokenManagerType, abi.encode(msg.sender.toBytes(), tokenAddress));
    }

    /**
     * @notice Used to deploy a standardized token alongside a TokenManager in another chain. If the `distributor` is empty
     * bytes then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
     * @param salt the salt to be used.
     * @param name the name of the token to be deployed.
     * @param symbol the symbol of the token to be deployed.
     * @param decimals the decimals of the token to be deployed.
     * @param distributor the address that will be able to mint and burn the deployed token.
     * @param destinationChain the name of the destination chain to deploy to.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount
     * specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
     */
    function deployAndRegisterRemoteStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteStandardizedToken(tokenId, name, symbol, decimals, distributor, operator, destinationChain, gasValue);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
     * sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param commandId the sendHash detected at the sourceChain.
     */
    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted(commandId);

        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());

        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);

        _setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, caller);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have
     * detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param sourceChain the name of the chain where the call came from.
     * @param sourceAddress the caller of callContractWithInterchainToken.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param data the data to be passed to destinationAddress after giving them the tokens specified.
     * @param commandId the sendHash detected at the sourceChain.
     */
    function expressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) external {
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted(commandId);

        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());

        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);

        _expressExecuteWithInterchainTokenToken(tokenId, destinationAddress, sourceChain, sourceAddress, data, amount);

        _setExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, caller);
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    /**
     * @notice Transmit a sendTokenWithData for the given tokenId. Only callable by a token manager.
     * @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress the address where the token is coming from, which will also be used for reimburment of gas.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param metadata the data to be passed to the destiantion.
     */
    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes memory payload;
        if (metadata.length < 4) {
            payload = abi.encode(SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount);
            _callContract(destinationChain, payload, msg.value, sourceAddress);
            emit TokenSent(tokenId, destinationChain, destinationAddress, amount);
            return;
        }
        uint32 version;
        (version, metadata) = _decodeMetadata(metadata);
        if (version > 0) revert InvalidMetadataVersion(version);
        payload = abi.encode(SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destinationAddress, amount, sourceAddress.toBytes(), metadata);
        _callContract(destinationChain, payload, msg.value, sourceAddress);
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, metadata);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds an array of the token Ids of the tokenManagers to set the flow limit of.
     * @param flowLimits the flowLimits to set
     */
    function setFlowLimit(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyOperator {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenIds[i]));
            tokenManager.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to pause the entire service.
     * @param paused what value to set paused to.
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

    function _sanitizeTokenManagerImplementation(
        address[] memory implementaions,
        TokenManagerType tokenManagerType
    ) internal pure returns (address implementation) {
        implementation = implementaions[uint256(tokenManagerType)];
        if (implementation == address(0)) revert ZeroAddress();
        if (ITokenManager(implementation).implementationType() != uint256(tokenManagerType)) revert InvalidTokenManagerImplementation();
    }

    /**
     * @notice Executes operations based on the payload and selector.
     * @param sourceChain The chain where the transaction originates from
     * @param sourceAddress The address where the transaction originates from
     * @param payload The encoded data payload for the transaction
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) notPaused {
        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SELECTOR_SEND_TOKEN) {
            _processSendTokenPayload(sourceChain, payload);
        } else if (selector == SELECTOR_SEND_TOKEN_WITH_DATA) {
            _processSendTokenWithDataPayload(sourceChain, payload);
        } else if (selector == SELECTOR_DEPLOY_TOKEN_MANAGER) {
            _processDeployTokenManagerPayload(payload);
        } else if (selector == SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN) {
            _processDeployStandardizedTokenAndManagerPayload(payload);
        } else {
            revert SelectorUnknown();
        }
    }

    /**
     * @notice Processes the payload data for a send token call
     * @param sourceChain The chain where the transaction originates from
     * @param payload The encoded data payload to be processed
     */
    function _processSendTokenPayload(string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount) = abi.decode(payload, (uint256, bytes32, bytes, uint256));
        bytes32 commandId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            commandId := calldataload(4)
        }
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        address expressCaller = _popExpressReceiveToken(tokenId, destinationAddress, amount, commandId);
        if (expressCaller == address(0)) {
            amount = tokenManager.giveToken(destinationAddress, amount);
            emit TokenReceived(tokenId, sourceChain, destinationAddress, amount);
        } else {
            amount = tokenManager.giveToken(expressCaller, amount);
        }
    }

    /**
     * @notice Processes a send token with data payload.
     * @param sourceChain The chain where the transaction originates from
     * @param payload The encoded data payload to be processed
     */
    function _processSendTokenWithDataPayload(string calldata sourceChain, bytes calldata payload) internal {
        bytes32 tokenId;
        uint256 amount;
        bytes memory sourceAddress;
        bytes memory data;
        address destinationAddress;
        bytes32 commandId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            commandId := calldataload(4)
        }
        {
            bytes memory destinationAddressBytes;
            (, tokenId, destinationAddressBytes, amount, sourceAddress, data) = abi.decode(
                payload,
                (uint256, bytes32, bytes, uint256, bytes, bytes)
            );
            destinationAddress = destinationAddressBytes.toAddress();
        }
        ITokenManager tokenManager = ITokenManager(getTokenManagerAddress(tokenId));
        {
            address expressCaller = _popExpressReceiveTokenWithData(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId
            );
            if (expressCaller != address(0)) {
                amount = tokenManager.giveToken(expressCaller, amount);
                return;
            }
        }
        amount = tokenManager.giveToken(destinationAddress, amount);
        IInterchainTokenExpressExecutable(destinationAddress).executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
        emit TokenReceivedWithData(tokenId, sourceChain, destinationAddress, amount, sourceAddress, data);
    }

    /**
     * @notice Processes a deploy token manager payload.
     * @param payload The encoded data payload to be processed
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
     * @param payload The encoded data payload to be processed
     */
    function _processDeployStandardizedTokenAndManagerPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenId,
            string memory name,
            string memory symbol,
            uint8 decimals,
            bytes memory distributorBytes,
            bytes memory operatorBytes
        ) = abi.decode(payload, (uint256, bytes32, string, string, uint8, bytes, bytes));
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        address distributor = distributorBytes.length > 0 ? distributorBytes.toAddress() : tokenManagerAddress;
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, 0, distributor);
        TokenManagerType tokenManagerType = distributor == tokenManagerAddress ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        _deployTokenManager(
            tokenId,
            tokenManagerType,
            abi.encode(operatorBytes.length == 0 ? address(this).toBytes() : operatorBytes, tokenAddress)
        );
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called
     * @param payload The data payload for the transaction
     * @param gasValue The amount of gas to be paid for the transaction
     * @param refundTo The address where the unused gas amount should be refunded to
     */
    function _callContract(string calldata destinationChain, bytes memory payload, uint256 gasValue, address refundTo) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                refundTo
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _validateToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    /**
     * @notice Deploys a token manager on a destination chain.
     * @param tokenId The ID of the token
     * @param destinationChain The chain where the token manager will be deployed
     * @param gasValue The amount of gas to be paid for the transaction
     * @param tokenManagerType The type of token manager to be deployed
     * @param params Additional parameters for the token manager deployment
     */
    function _deployRemoteTokenManager(
        bytes32 tokenId,
        string calldata destinationChain,
        uint256 gasValue,
        TokenManagerType tokenManagerType,
        bytes memory params
    ) internal {
        bytes memory payload = abi.encode(SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, tokenManagerType, params);
        _callContract(destinationChain, payload, gasValue, msg.sender);
        emit RemoteTokenManagerDeploymentInitialized(tokenId, destinationChain, gasValue, tokenManagerType, params);
    }

    /**
     * @notice Deploys a standardized token on a destination chain.
     * @param tokenId The ID of the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     * @param distributor The distributor address for the token
     * @param destinationChain The destination chain where the token will be deployed
     * @param gasValue The amount of gas to be paid for the transaction
     */
    function _deployRemoteStandardizedToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) internal {
        bytes memory payload = abi.encode(
            SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            operator
        );
        _callContract(destinationChain, payload, gasValue, msg.sender);
        emit RemoteStandardizedTokenAndManagerDeploymentInitialized(
            tokenId,
            name,
            symbol,
            decimals,
            distributor,
            operator,
            destinationChain,
            gasValue
        );
    }

    /**
     * @notice Deploys a token manager
     * @param tokenId The ID of the token
     * @param tokenManagerType The type of the token manager to be deployed
     * @param params Additional parameters for the token manager deployment
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = tokenManagerDeployer.delegatecall(
            abi.encodeWithSelector(ITokenManagerDeployer.deployTokenManager.selector, tokenId, tokenManagerType, params)
        );
        if (!success) {
            revert TokenManagerDeploymentFailed();
        }
        emit TokenManagerDeployed(tokenId, tokenManagerType, params);
    }

    /**
     * @notice Compute the salt for a standardized token deployment.
     * @param tokenId The ID of the token
     * @return salt The computed salt for the token deployment
     */
    function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        return keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_SALT, tokenId));
    }

    /**
     * @notice Deploys a standardized token.
     * @param tokenId The ID of the token
     * @param distributor The distributor address for the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     * @param mintAmount The amount of tokens to be minted upon deployment
     * @param mintTo The address where the minted tokens will be sent upon deployment
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
        bytes32 salt = _getStandardizedTokenSalt(tokenId);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        // solhint-disable-next-line avoid-low-level-calls
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
        emit StandardizedTokenDeployed(tokenId, name, symbol, decimals, mintAmount, mintTo);
    }

    function _decodeMetadata(bytes calldata metadata) internal pure returns (uint32 version, bytes calldata data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.length := sub(metadata.length, 4)
            data.offset := add(metadata.offset, 4)
            version := calldataload(sub(metadata.offset, 28))
        }
    }

    function _expressExecuteWithInterchainTokenToken(
        bytes32 tokenId,
        address destinationAddress,
        string memory sourceChain,
        bytes memory sourceAddress,
        bytes calldata data,
        uint256 amount
    ) internal {
        IInterchainTokenExpressExecutable(destinationAddress).expressExecuteWithInterchainToken(
            sourceChain,
            sourceAddress,
            data,
            tokenId,
            amount
        );
    }
}
