// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { ExpressExecutorTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/express/ExpressExecutorTracker.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Address } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Address.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Pausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Pausable.sol';
import { InterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/InterchainAddressTracker.sol';

import { IInterchainTokenService } from './interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from './interfaces/ITokenManagerProxy.sol';
import { ITokenHandler } from './interfaces/ITokenHandler.sol';
import { ITokenManagerDeployer } from './interfaces/ITokenManagerDeployer.sol';
import { IInterchainTokenDeployer } from './interfaces/IInterchainTokenDeployer.sol';
import { IInterchainTokenExecutable } from './interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenExpressExecutable } from './interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IERC20Named } from './interfaces/IERC20Named.sol';

import { Operator } from './utils/Operator.sol';

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
    Create3Address,
    ExpressExecutorTracker,
    InterchainAddressTracker,
    IInterchainTokenService
{
    using AddressBytes for bytes;
    using AddressBytes for address;

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
    uint256 private constant MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 2;

    /**
     * @dev Tokens and token managers deployed via the Token Factory contract use a special deployer address.
     * This removes the dependency on the address the token factory was deployed too to be able to derive the same tokenId.
     */
    address internal constant TOKEN_FACTORY_DEPLOYER = address(0);

    /**
     * @dev Latest version of metadata that's supported.
     */

    enum MetadataVersion {
        CONTRACT_CALL,
        EXPRESS_CALL
    }

    uint32 internal constant LATEST_METADATA_VERSION = 1;

    /**
     * @notice Constructor for the Interchain Token Service.
     * @dev All of the variables passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ The address of the TokenManagerDeployer.
     * @param interchainTokenDeployer_ The address of the InterchainTokenDeployer.
     * @param gateway_ The address of the AxelarGateway.
     * @param gasService_ The address of the AxelarGasService.
     * @param interchainTokenFactory_ The address of the InterchainTokenFactory.
     * @param chainName_ The name of the chain that this contract is deployed on.
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
        address tokenManagerImplementation_,
        address tokenHandler_
    ) {
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
    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!isTrustedAddress(sourceChain, sourceAddress)) revert NotRemoteService();

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
     * @notice Returns the address of a TokenManager from a specific tokenId.
     * @dev The TokenManager needs to exist already.
     * @param tokenId The tokenId.
     * @return tokenManagerAddress_ The deployment address of the TokenManager.
     */
    function validTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_) {
        tokenManagerAddress_ = tokenManagerAddress(tokenId);
        if (tokenManagerAddress_.code.length == 0) revert TokenManagerDoesNotExist(tokenId);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId The tokenId.
     * @return tokenAddress The address of the token.
     */
    function validTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        address tokenManagerAddress_ = validTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenManagerAddress_).tokenAddress();
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

    /**
     * @notice Getter function for the flow limit of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowLimit_ The flow limit.
     */
    function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_) {
        ITokenManager tokenManager_ = ITokenManager(validTokenManagerAddress(tokenId));
        flowLimit_ = tokenManager_.flowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowOutAmount_ The flow out amount.
     */
    function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_) {
        ITokenManager tokenManager_ = ITokenManager(validTokenManagerAddress(tokenId));
        flowOutAmount_ = tokenManager_.flowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowInAmount_ The flow in amount.
     */
    function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_) {
        ITokenManager tokenManager_ = ITokenManager(validTokenManagerAddress(tokenId));
        flowInAmount_ = tokenManager_.flowInAmount();
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Used to deploy remote custom TokenManagers.
     * @dev At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls.
     * @param salt The salt to be used during deployment.
     * @param destinationChain The name of the chain to deploy the TokenManager and standardized token to.
     * @param tokenManagerType The type of TokenManager to be deployed.
     * @param params The params that will be used to initialize the TokenManager.
     * @param gasValue The amount of native tokens to be used to pay for gas for the remote deployment.
     * @return tokenId The tokenId corresponding to the deployed TokenManager.
     */
    function deployTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable whenNotPaused returns (bytes32 tokenId) {
        address deployer = msg.sender;

        if (deployer == interchainTokenFactory) deployer = TOKEN_FACTORY_DEPLOYER;

        tokenId = interchainTokenId(deployer, salt);

        emit InterchainTokenIdClaimed(tokenId, deployer, salt);

        if (bytes(destinationChain).length == 0) {
            _deployTokenManager(tokenId, tokenManagerType, params);
        } else {
            _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
        }
    }

    /**
     * @notice Used to deploy an interchain token alongside a TokenManager in another chain.
     * @dev At least the `gasValue` amount of native token must be passed to the function call. `gasValue` exists because this function can be
     * part of a multicall involving multiple functions that could make remote contract calls. If the `minter` parameter is empty bytes then
     * a mint/burn TokenManager is used, otherwise a lock/unlock TokenManager is used.
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
    ) external payable whenNotPaused returns (bytes32 tokenId) {
        address deployer = msg.sender;

        if (deployer == interchainTokenFactory) deployer = TOKEN_FACTORY_DEPLOYER;

        tokenId = interchainTokenId(deployer, salt);

        if (bytes(destinationChain).length == 0) {
            address tokenAddress = _deployInterchainToken(tokenId, minter, name, symbol, decimals);

            _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(minter, tokenAddress));
        } else {
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
    ) public view virtual onlyRemoteService(sourceChain, sourceAddress) whenNotPaused returns (address, uint256) {
        (uint256 messageType, bytes32 tokenId, , uint256 amount) = abi.decode(payload, (uint256, bytes32, bytes, uint256));

        if (messageType != MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            revert InvalidExpressMessageType(messageType);
        }

        return (validTokenAddress(tokenId), amount);
    }

    /**
     * @notice Express executes operations based on the payload and selector.
     * @param commandId The unique message id.
     * @param sourceChain The chain where the transaction originates from.
     * @param sourceAddress The address of the remote ITS where the transaction originates from.
     * @param payload The encoded data payload for the transaction.
     */
    function expressExecute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) public payable whenNotPaused {
        uint256 messageType = abi.decode(payload, (uint256));
        if (messageType != MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            revert InvalidExpressMessageType(messageType);
        }

        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted();

        address expressExecutor = msg.sender;
        bytes32 payloadHash = keccak256(payload);

        emit ExpressExecuted(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _setExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

        _expressExecute(commandId, sourceChain, payload);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
     * interchainTransfer that matches the parameters passed here.
     * @param commandId The unique message id of the transfer being expressed.
     * @param sourceChain the name of the chain where the interchainTransfer originated from.
     * @param payload the payload of the receive token
     */
    function _expressExecute(bytes32 commandId, string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory sourceAddress, bytes memory destinationAddressBytes, uint256 amount, bytes memory data) = abi
            .decode(payload, (uint256, bytes32, bytes, bytes, uint256, bytes));
        address destinationAddress = destinationAddressBytes.toAddress();

        IERC20 token;
        {
            ITokenManager tokenManager_ = ITokenManager(tokenManagerAddress(tokenId));
            token = IERC20(tokenManager_.tokenAddress());

            (bool success, bytes memory returnData) = tokenHandler.delegatecall(
                abi.encodeWithSelector(
                    ITokenHandler.transferTokenFrom.selector,
                    tokenManager_.implementationType(),
                    address(token),
                    msg.sender,
                    destinationAddress,
                    amount
                )
            );
            if (!success) revert TokenHandlerFailed(returnData);
            amount = abi.decode(returnData, (uint256));
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

    /**
     * @notice Initiates an interchain transfer of a specified token to a destination chain.
     * @dev The function retrieves the TokenManager associated with the tokenId.
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
    ) external payable whenNotPaused {
        string memory symbol;
        (amount, symbol) = _takeToken(tokenId, msg.sender, amount, false);

        (MetadataVersion metadataVersion, bytes memory data) = _decodeMetadata(metadata);

        _transmitInterchainTransfer(
            tokenId,
            msg.sender,
            destinationChain,
            destinationAddress,
            amount,
            metadataVersion,
            data,
            symbol,
            gasValue
        );
    }

    /**
     * @notice Initiates an interchain call contract with interchain token to a destination chain.
     * @param tokenId The unique identifier of the token to be transferred.
     * @param destinationChain The destination chain to send the tokens to.
     * @param destinationAddress The address on the destination chain to send the tokens to.
     * @param amount The amount of tokens to be transferred.
     * @param data Additional data to be passed along with the transfer.
     */
    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes memory data,
        uint256 gasValue
    ) external payable whenNotPaused {
        if (data.length == 0) revert EmptyData();
        string memory symbol;
        (amount, symbol) = _takeToken(tokenId, msg.sender, amount, false);

        _transmitInterchainTransfer(
            tokenId,
            msg.sender,
            destinationChain,
            destinationAddress,
            amount,
            MetadataVersion.CONTRACT_CALL,
            data,
            symbol,
            gasValue
        );
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
        string memory symbol;
        (amount, symbol) = _takeToken(tokenId, sourceAddress, amount, true);

        (MetadataVersion metadataVersion, bytes memory data) = _decodeMetadata(metadata);

        _transmitInterchainTransfer(
            tokenId,
            sourceAddress,
            destinationChain,
            destinationAddress,
            amount,
            metadataVersion,
            data,
            symbol,
            msg.value
        );
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
            ITokenManager tokenManager_ = ITokenManager(validTokenManagerAddress(tokenIds[i]));
            // slither-disable-next-line calls-loop
            tokenManager_.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to set a trusted address for a chain.
     * @param chain The chain to set the trusted address of.
     * @param address_ The address to set as trusted.
     */
    function setTrustedAddress(string memory chain, string memory address_) external onlyOwner {
        _setTrustedAddress(chain, address_);
    }

    /**
     * @notice Used to remove a trusted address for a chain.
     * @param chain The chain to set the trusted address of.
     */
    function removeTrustedAddress(string memory chain) external onlyOwner {
        _removeTrustedAddress(chain);
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

    /****************\
    INTERNAL FUNCTIONS
    \****************/

    function _setup(bytes calldata params) internal override {
        (address operator, string memory chainName_, string[] memory trustedChainNames, string[] memory trustedAddresses) = abi.decode(
            params,
            (address, string, string[], string[])
        );
        uint256 length = trustedChainNames.length;

        if (operator == address(0)) revert ZeroAddress();
        if (bytes(chainName_).length == 0 || keccak256(bytes(chainName_)) != chainNameHash) revert InvalidChainName();
        if (length != trustedAddresses.length) revert LengthMismatch();

        _addOperator(operator);
        _setChainName(chainName_);

        for (uint256 i; i < length; ++i) {
            _setTrustedAddress(trustedChainNames[i], trustedAddresses[i]);
        }
    }

    /**
     * @notice Executes operations based on the payload and selector.
     * @param commandId The unique message id.
     * @param sourceChain The chain where the transaction originates from.
     * @param sourceAddress The address of the remote ITS where the transaction originates from.
     * @param payload The encoded data payload for the transaction.
     */
    function execute(bytes32 commandId, string calldata sourceChain, string calldata sourceAddress, bytes calldata payload) public {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();

        _execute(commandId, sourceChain, sourceAddress, payload, payloadHash);
    }

    function contractCallWithTokenValue(
        string calldata /*sourceChain*/,
        string calldata /*sourceAddress*/,
        bytes calldata /*payload*/,
        string calldata /*symbol*/,
        uint256 /*amount*/
    ) public view virtual returns (address, uint256) {
        revert ExecuteWithTokenNotSupported();
    }

    function expressExecuteWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata /*tokenSymbol*/,
        uint256 /*amount*/
    ) external payable {
        // It should be ok to ignore the symbol and amount since this info exists on the payload.
        expressExecute(commandId, sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _execute(commandId, sourceChain, sourceAddress, payload, payloadHash);
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
        string calldata sourceChain,
        bytes calldata payload
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

        // Return token to the existing express caller
        if (expressExecutor != address(0)) {
            // slither-disable-next-line unused-return
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
     * @notice Processes a deploy interchain token manager payload.
     * @param payload The encoded data payload to be processed.
     */
    function _processDeployInterchainTokenPayload(bytes calldata payload) internal {
        (, bytes32 tokenId, string memory name, string memory symbol, uint8 decimals, bytes memory minterBytes) = abi.decode(
            payload,
            (uint256, bytes32, string, string, uint8, bytes)
        );
        address tokenAddress;

        tokenAddress = _deployInterchainToken(tokenId, minterBytes, name, symbol, decimals);

        _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(minterBytes, tokenAddress));
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _callContract(
        string calldata destinationChain,
        bytes memory payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) internal {
        string memory destinationAddress = trustedAddress(destinationChain);
        if (bytes(destinationAddress).length == 0) revert UntrustedChain();

        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                gasService.payNativeGasForContractCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                gasService.payNativeGasForExpressCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload and gateway token
     * @param destinationChain The target chain where the contract will be called.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _callContractWithToken(
        string calldata destinationChain,
        bytes memory payload,
        string memory symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) internal {
        string memory destinationAddress = trustedAddress(destinationChain);
        if (bytes(destinationAddress).length == 0) revert UntrustedChain();

        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                gasService.payNativeGasForExpressCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }

    function _execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        bytes32 payloadHash
    ) internal onlyRemoteService(sourceChain, sourceAddress) whenNotPaused {
        uint256 messageType = abi.decode(payload, (uint256));
        if (messageType == MESSAGE_TYPE_INTERCHAIN_TRANSFER) {
            address expressExecutor = _popExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash);

            if (expressExecutor != address(0)) {
                emit ExpressExecutionFulfilled(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);
            }

            _processInterchainTransferPayload(commandId, expressExecutor, sourceChain, payload);
        } else if (messageType == MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER) {
            _processDeployTokenManagerPayload(payload);
        } else if (messageType == MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN) {
            _processDeployInterchainTokenPayload(payload);
        } else {
            revert InvalidMessageType(messageType);
        }
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
        // slither-disable-next-line unused-return
        validTokenManagerAddress(tokenId);

        emit TokenManagerDeploymentStarted(tokenId, destinationChain, tokenManagerType, params);

        bytes memory payload = abi.encode(MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER, tokenId, tokenManagerType, params);

        _callContract(destinationChain, payload, MetadataVersion.CONTRACT_CALL, gasValue);
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
        // slither-disable-next-line unused-return
        validTokenManagerAddress(tokenId);

        // slither-disable-next-line reentrancy-events
        emit InterchainTokenDeploymentStarted(tokenId, name, symbol, decimals, minter, destinationChain);

        bytes memory payload = abi.encode(MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, minter);

        _callContract(destinationChain, payload, MetadataVersion.CONTRACT_CALL, gasValue);
    }

    /**
     * @notice Deploys a token manager.
     * @param tokenId The ID of the token.
     * @param tokenManagerType The type of the token manager to be deployed.
     * @param params Additional parameters for the token manager deployment.
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) internal {
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
        return keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, tokenId));
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
     * @return version The version number extracted from the metadata.
     * @return data The data bytes extracted from the metadata.
     */
    function _decodeMetadata(bytes calldata metadata) internal pure returns (MetadataVersion version, bytes memory data) {
        if (metadata.length < 4) return (MetadataVersion.CONTRACT_CALL, data);

        uint32 versionUint = uint32(bytes4(metadata[:4]));
        if (versionUint > LATEST_METADATA_VERSION) revert InvalidMetadataVersion(versionUint);

        version = MetadataVersion(versionUint);

        if (metadata.length == 4) return (version, data);

        data = metadata[4:];
    }

    /**
     * @notice Transmit a callContractWithInterchainToken for the given tokenId.
     * @param tokenId The tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress The address where the token is coming from, which will also be used for gas reimbursement.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of tokens to send.
     * @param metadataVersion The version of the metadata.
     * @param data The data to be passed with the token transfer.
     */
    function _transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        MetadataVersion metadataVersion,
        bytes memory data,
        string memory symbol,
        uint256 gasValue
    ) internal {
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
        if (bytes(symbol).length > 0) {
            _callContractWithToken(destinationChain, payload, symbol, amount, metadataVersion, gasValue);
        } else {
            _callContract(destinationChain, payload, metadataVersion, gasValue);
        }
    }

    /**
     * @dev Takes token from a sender via the token service. `tokenOnly` indicates if the caller should be restricted to the token only.
     */
    function _takeToken(bytes32 tokenId, address from, uint256 amount, bool tokenOnly) internal returns (uint256, string memory symbol) {
        address tokenManager_ = tokenManagerAddress(tokenId);
        uint256 tokenManagerType;
        address tokenAddress;

        (tokenManagerType, tokenAddress) = ITokenManagerProxy(tokenManager_).getImplementationTypeAndTokenAddress();

        if (tokenOnly && msg.sender != tokenAddress) revert NotToken(msg.sender, tokenAddress);

        (bool success, bytes memory data) = tokenHandler.delegatecall(
            abi.encodeWithSelector(ITokenHandler.takeToken.selector, tokenManagerType, tokenAddress, tokenManager_, from, amount)
        );
        if (!success) revert TakeTokenFailed(data);
        amount = abi.decode(data, (uint256));

        /// @dev Track the flow amount being sent out as a message
        ITokenManager(tokenManager_).addFlowOut(amount);
        if (tokenManagerType == uint256(TokenManagerType.GATEWAY)) {
            symbol = IERC20Named(tokenAddress).symbol();
        }
        return (amount, symbol);
    }

    /**
     * @dev Gives token to recipient via the token service.
     */
    function _giveToken(bytes32 tokenId, address to, uint256 amount) internal returns (uint256, address) {
        address tokenManager_ = tokenManagerAddress(tokenId);

        (uint256 tokenManagerType, address tokenAddress) = ITokenManagerProxy(tokenManager_).getImplementationTypeAndTokenAddress();

        /// @dev Track the flow amount being received via the message
        ITokenManager(tokenManager_).addFlowIn(amount);

        (bool success, bytes memory data) = tokenHandler.delegatecall(
            abi.encodeWithSelector(ITokenHandler.giveToken.selector, tokenManagerType, tokenAddress, tokenManager_, to, amount)
        );
        if (!success) revert GiveTokenFailed(data);
        amount = abi.decode(data, (uint256));

        return (amount, tokenAddress);
    }
}
