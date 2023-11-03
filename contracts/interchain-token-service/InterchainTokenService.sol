// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { ExpressExecutorTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/express/ExpressExecutorTracker.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Address } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Address.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/Bytes32String.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { IInterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainAddressTracker.sol';
import { Pausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Pausable.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { Operatable } from '../utils/Operatable.sol';

/**
 * @title The Interchain Token Service
 * @notice This contract is responsible for facilitating cross chain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.
 * @dev The only storage used here is for ExpressCalls
 */
contract InterchainTokenService is
    Upgradable,
    Operatable,
    Pausable,
    Multicall,
    Create3Address,
    ExpressExecutorTracker,
    IInterchainTokenService
{
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytes for bytes;
    using AddressBytes for address;
    using SafeTokenTransferFrom for IERC20;

    address internal immutable implementationLockUnlock;
    address internal immutable implementationMintBurn;
    address internal immutable implementationMintBurnFrom;
    address internal immutable implementationLockUnlockFee;
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;
    IInterchainAddressTracker public immutable interchainAddressTracker;
    address public immutable tokenManagerDeployer;
    address public immutable interchainTokenDeployer;
    bytes32 public immutable chainNameHash;

    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('its-custom-token-id');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('its-interchain-token-salt');

    uint256 private constant SELECTOR_RECEIVE_TOKEN = 1;
    uint256 private constant SELECTOR_RECEIVE_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
    uint256 private constant SELECTOR_DEPLOY_INTERCHAIN_TOKEN = 4;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');
    bytes32 private constant EXECUTE_SUCCESS = keccak256('its-execute-success');
    bytes32 private constant EXPRESS_EXECUTE_SUCCESS = keccak256('its-express-execute-success');

    /**
     * @dev All of the variables passed here are stored as immutable variables.
     * @param tokenManagerDeployer_ the address of the TokenManagerDeployer.
     * @param interchainTokenDeployer_ the address of the InterchainTokenDeployer.
     * @param gateway_ the address of the AxelarGateway.
     * @param gasService_ the address of the AxelarGasService.
     * @param interchainRouter_ the address of the InterchainAddressTracker.
     * @param tokenManagerImplementations this needs to have implementations in the order: Mint-burn, Mint-burn from, Lock-unlock, and Lock-unlock with fee.
     */
    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainRouter_,
        address[] memory tokenManagerImplementations
    ) {
        if (
            interchainRouter_ == address(0) ||
            gasService_ == address(0) ||
            tokenManagerDeployer_ == address(0) ||
            interchainTokenDeployer_ == address(0) ||
            gateway_ == address(0)
        ) revert ZeroAddress();

        gateway = IAxelarGateway(gateway_);
        interchainAddressTracker = IInterchainAddressTracker(interchainRouter_);
        gasService = IAxelarGasService(gasService_);
        tokenManagerDeployer = tokenManagerDeployer_;
        interchainTokenDeployer = interchainTokenDeployer_;

        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        implementationMintBurn = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN);
        implementationMintBurnFrom = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN_FROM);
        implementationLockUnlock = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK);
        implementationLockUnlockFee = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK_FEE);
        string memory chainName_ = interchainAddressTracker.chainName();
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
        if (!interchainAddressTracker.isTrustedAddress(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    /**
     * @notice This modifier is used to ensure certain functions can only be called by TokenManagers.
     * @param tokenId the `tokenId` of the TokenManager trying to perform the call.
     */
    modifier onlyTokenManager(bytes32 tokenId) {
        address tokenManager = tokenManagerAddress(tokenId);
        if (msg.sender != tokenManager) revert NotTokenManager(msg.sender, tokenManager);

        _;
    }

    /*****\
    GETTERS
    \*****/

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress_ deployment address of the TokenManager.
     */
    function tokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_) {
        tokenManagerAddress_ = _create3Address(tokenId);
    }

    /**
     * @notice Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.
     * @param tokenId the tokenId.
     * @return tokenManagerAddress_ deployment address of the TokenManager.
     */
    function validTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress_) {
        tokenManagerAddress_ = tokenManagerAddress(tokenId);
        if (tokenManagerAddress_.code.length == 0) revert TokenManagerDoesNotExist(tokenId);
    }

    /**
     * @notice Returns the address of the token that an existing tokenManager points to.
     * @param tokenId the tokenId.
     * @return tokenAddress_ the address of the token.
     */
    function tokenAddress(bytes32 tokenId) external view returns (address tokenAddress_) {
        address tokenManagerAddress_ = validTokenManagerAddress(tokenId);
        tokenAddress_ = ITokenManager(tokenManagerAddress_).tokenAddress();
    }

    /**
     * @notice Returns the address of the interchain token that would be deployed with a given tokenId.
     * The token does not need to exist.
     * @param tokenId the tokenId.
     * @return tokenAddress_ the address of the interchain token.
     */
    function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress_) {
        tokenId = _getInterchainTokenSalt(tokenId);
        tokenAddress_ = _create3Address(tokenId);
    }

    /**
     * @notice Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt.
     * This will not depend on what chain it is called from, unlike canonical tokenIds.
     * @param sender the address of the TokenManager deployer.
     * @param salt the salt that the deployer uses for the deployment.
     * @return tokenId the tokenId that the custom TokenManager would get (or has gotten).
     */
    function interchainTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_TOKEN_ID, sender, salt));
    }

    /**
     * @notice Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
     * to figure out their implementations
     * @param tokenManagerType the type of the TokenManager.
     * @return tokenManagerAddress the address of the TokenManagerImplementation.
     */
    function tokenManagerImplementation(uint256 tokenManagerType) external view returns (address) {
        if (tokenManagerType > uint256(type(TokenManagerType).max)) revert InvalidImplementation();

        if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) return implementationMintBurn;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN_FROM) return implementationMintBurnFrom;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) return implementationLockUnlock;
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK_FEE) return implementationLockUnlockFee;

        revert InvalidImplementation();
    }

    /**
     * @notice Getter function for the flow limit of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowLimit_ the flow limit.
     */
    function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_) {
        ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));
        flowLimit_ = tokenManager.flowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowOutAmount_ the flow out amount.
     */
    function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_) {
        ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));
        flowOutAmount_ = tokenManager.flowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing token manager with a give token ID.
     * @param tokenId the token ID of the TokenManager.
     * @return flowInAmount_ the flow in amount.
     */
    function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_) {
        ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));
        flowInAmount_ = tokenManager.flowInAmount();
    }

    /************\
    USER FUNCTIONS
    \************/

    /**
     * @notice Used to deploy remote custom TokenManagers.
     * @param salt the salt to be used.
     * @param destinationChain the name of the chain to deploy the TokenManager and interchain token to.
     * @param tokenManagerType the type of TokenManager to be deployed.
     * @param params the params that will be used to initialize the TokenManager.
     * @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least
     * the amount specified needs to be passed to the call
     * @dev `gasValue` exists because this function can be part of a multicall involving multiple functions
     * that could make remote contract calls.
     */
    function deployTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable whenNotPaused returns (bytes32 tokenId) {
        address deployer_ = msg.sender;
        tokenId = interchainTokenId(deployer_, salt);

        emit CustomTokenIdClaimed(tokenId, deployer_, salt);
        if (bytes(destinationChain).length == 0) {
            _deployTokenManager(tokenId, tokenManagerType, params);
        } else {
            _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
        }
    }

    /**
     * @notice Used to deploy a interchain token alongside a TokenManager in another chain. If the `distributor` is empty
     * bytes then a mint/burn TokenManager is used. Otherwise a lock/unlock TokenManager is used.
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
    function deployInterchainToken(
        bytes32 salt,
        string calldata destinationChain,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        uint256 gasValue
    ) external payable whenNotPaused {
        bytes32 tokenId = interchainTokenId(msg.sender, salt);

        if (bytes(destinationChain).length == 0) {
            address tokenAddress_;
            tokenAddress_ = _deployInterchainToken(tokenId, distributor, name, symbol, decimals);
            _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(operator, tokenAddress_));
        } else {
            _deployRemoteInterchainToken(tokenId, name, symbol, decimals, distributor, operator, destinationChain, gasValue);
        }
    }

    // Returns the amount of token that this call is worth. If `tokenAddress` is `0`, then value is in terms of the native token, otherwise it's in terms of the token address.
    function contractCallValue(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) public view virtual onlyRemoteService(sourceChain, sourceAddress) whenNotPaused returns (address, uint256) {
        (uint256 selector, bytes32 tokenId, , uint256 amount) = abi.decode(payload, (uint256, bytes32, bytes, uint256));

        if (selector != SELECTOR_RECEIVE_TOKEN && selector != SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            revert InvalidExpressSelector(selector);
        }

        ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));
        return (tokenManager.tokenAddress(), amount);
    }

    function expressExecute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external payable whenNotPaused {
        uint256 selector = abi.decode(payload, (uint256));
        if (selector != SELECTOR_RECEIVE_TOKEN && selector != SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            revert InvalidExpressSelector(selector);
        }
        if (gateway.isCommandExecuted(commandId)) revert AlreadyExecuted();

        address expressExecutor = msg.sender;
        bytes32 payloadHash = keccak256(payload);

        _setExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);
        _expressExecute(sourceChain, payload);

        emit ExpressExecuted(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);
    }

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing
     * interchainTransfer that matches the parameters passed here.
     * @dev This is not to be used with fee on transfer tokens as it will incur losses for the express caller.
     * @param sourceChain the name of the chain where the interchainTransfer originated from.
     * @param payload the payload of the receive token
     */
    function _expressExecute(string calldata sourceChain, bytes calldata payload) internal {
        (uint256 selector, bytes32 tokenId, bytes memory sourceAddress, bytes memory destinationAddressBytes, uint256 amount) = abi.decode(
            payload,
            (uint256, bytes32, bytes, bytes, uint256)
        );
        address destinationAddress = destinationAddressBytes.toAddress();

        IERC20 token;
        {
            ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));
            token = IERC20(tokenManager.tokenAddress());
        }

        token.safeTransferFrom(msg.sender, destinationAddress, amount);

        if (selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            (, , , , , bytes memory data) = abi.decode(payload, (uint256, bytes32, bytes, bytes, uint256, bytes));

            bytes32 result = IInterchainTokenExpressExecutable(destinationAddress).expressExecuteWithInterchainToken(
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
     * @notice Transfer a token interchain.
     * @param tokenId the tokenId for the token link.
     * @param destinationChain the name of the chain to send the token to.
     * @param destinationAddress the recipient of the interchain transfer.
     * @param amount the amount of token to give.
     * @param metadata the data to be passed to the destination. If provided with a bytes4(0) prefix, it'll execute the destination contract.
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable whenNotPaused {
        ITokenManager tokenManager = ITokenManager(tokenManagerAddress(tokenId));
        amount = tokenManager.takeToken(msg.sender, amount);
        _transmitInterchainTransfer(tokenId, msg.sender, destinationChain, destinationAddress, amount, metadata);
    }

    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable whenNotPaused {
        ITokenManager tokenManager = ITokenManager(tokenManagerAddress(tokenId));
        amount = tokenManager.takeToken(msg.sender, amount);
        uint32 prefix = 0;
        _transmitInterchainTransfer(tokenId, msg.sender, destinationChain, destinationAddress, amount, abi.encodePacked(prefix, data));
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    /**
     * @notice Transmit an interchain transfer for the given tokenId. Only callable by a token manager.
     * @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress the address where the token is coming from, which will also be used for reimbursement of gas.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the destinationAddress for the interchainTransfer.
     * @param amount the amount of token to give.
     * @param metadata the data to be passed to the destination.
     */
    function transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable onlyTokenManager(tokenId) whenNotPaused {
        _transmitInterchainTransfer(tokenId, sourceAddress, destinationChain, destinationAddress, amount, metadata);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds an array of the token Ids of the tokenManagers to set the flow limit of.
     * @param flowLimits the flowLimits to set
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyRole(uint8(Roles.OPERATOR)) {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();

        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenIds[i]));
            // slither-disable-next-line calls-loop
            tokenManager.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Allows the owner to pause/unpause the token service.
     * @param paused whether to pause or unpause.
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
        _addOperator(params.toAddress());
    }

    function _sanitizeTokenManagerImplementation(
        address[] memory tokenManagerImplementations,
        TokenManagerType tokenManagerType
    ) internal pure returns (address implementation_) {
        implementation_ = tokenManagerImplementations[uint256(tokenManagerType)];
        if (implementation_ == address(0)) revert ZeroAddress();

        if (ITokenManager(implementation_).implementationType() != uint256(tokenManagerType))
            revert InvalidTokenManagerImplementationType(implementation_);
    }

    /**
     * @notice Executes operations based on the payload and selector.
     * @param sourceChain The chain where the transaction originates from
     * @param sourceAddress The address of the remote ITS where the transaction originates from
     * @param payload The encoded data payload for the transaction
     */
    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external onlyRemoteService(sourceChain, sourceAddress) whenNotPaused {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();

        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SELECTOR_RECEIVE_TOKEN || selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            address expressExecutor = _popExpressExecutor(commandId, sourceChain, sourceAddress, payloadHash);
            _processReceiveTokenPayload(expressExecutor, sourceChain, payload, selector);

            if (expressExecutor != address(0))
                emit ExpressExecutionFulfilled(commandId, sourceChain, sourceAddress, payloadHash, expressExecutor);

            return;
        }

        if (selector == SELECTOR_DEPLOY_TOKEN_MANAGER) return _processDeployTokenManagerPayload(payload);
        if (selector == SELECTOR_DEPLOY_INTERCHAIN_TOKEN) return _processDeployInterchainTokenPayload(payload);

        revert SelectorUnknown(selector);
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
        bytes32 /*commandId*/,
        string calldata /*sourceChain*/,
        string calldata /*sourceAddress*/,
        bytes calldata /*payload*/,
        string calldata /*tokenSymbol*/,
        uint256 /*amount*/
    ) external payable {
        revert ExecuteWithTokenNotSupported();
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
     * @notice Processes the payload data for a send token call
     * @param sourceChain The chain where the transaction originates from
     * @param payload The encoded data payload to be processed
     */
    function _processReceiveTokenPayload(
        address expressExecutor,
        string calldata sourceChain,
        bytes calldata payload,
        uint256 selector
    ) internal {
        bytes32 tokenId;
        bytes memory sourceAddress;
        address destinationAddress;
        uint256 amount;
        {
            bytes memory destinationAddressBytes;
            (, tokenId, sourceAddress, destinationAddressBytes, amount) = abi.decode(payload, (uint256, bytes32, bytes, bytes, uint256));
            destinationAddress = destinationAddressBytes.toAddress();
        }

        ITokenManager tokenManager = ITokenManager(validTokenManagerAddress(tokenId));

        // Return token to the existing express caller
        if (expressExecutor != address(0)) {
            // slither-disable-next-line unused-return
            tokenManager.giveToken(expressExecutor, amount);
            return;
        }

        amount = tokenManager.giveToken(destinationAddress, amount);

        if (selector == SELECTOR_RECEIVE_TOKEN_WITH_DATA) {
            bytes memory data;
            (, , , , , data) = abi.decode(payload, (uint256, bytes32, bytes, bytes, uint256, bytes));

            // slither-disable-next-line reentrancy-events
            emit TokenReceivedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount);

            bytes32 result = IInterchainTokenExecutable(destinationAddress).executeWithInterchainToken(
                sourceChain,
                sourceAddress,
                data,
                tokenId,
                tokenManager.tokenAddress(),
                amount
            );

            if (result != EXECUTE_SUCCESS) revert ExecuteWithInterchainTokenFailed(destinationAddress);
        } else {
            // slither-disable-next-line reentrancy-events
            emit TokenReceived(tokenId, sourceChain, sourceAddress, destinationAddress, amount);
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
     * @notice Process a deploy interchain token and manager payload.
     * @param payload The encoded data payload to be processed
     */
    function _processDeployInterchainTokenPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenId,
            string memory name,
            string memory symbol,
            uint8 decimals,
            bytes memory distributorBytes,
            bytes memory opeatorBytes
        ) = abi.decode(payload, (uint256, bytes32, string, string, uint8, bytes, bytes));
        address tokenAddress_;

        tokenAddress_ = _deployInterchainToken(tokenId, distributorBytes, name, symbol, decimals);
        _deployTokenManager(tokenId, TokenManagerType.MINT_BURN, abi.encode(opeatorBytes, tokenAddress_));
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called
     * @param payload The data payload for the transaction
     * @param gasValue The amount of gas to be paid for the transaction
     */
    function _callContract(string calldata destinationChain, bytes memory payload, uint256 gasValue) internal {
        string memory destinationAddress = interchainAddressTracker.trustedAddress(destinationChain);
        if (bytes(destinationAddress).length == 0) revert UntrustedChain(destinationChain);
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

    function _validateToken(address tokenAddress_) internal view returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress_);
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
        // slither-disable-next-line unused-return
        validTokenManagerAddress(tokenId);
        emit RemoteTokenManagerDeploymentInitialized(tokenId, destinationChain, gasValue, tokenManagerType, params);

        bytes memory payload = abi.encode(SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, tokenManagerType, params);
        _callContract(destinationChain, payload, gasValue);
    }

    /**
     * @notice Deploys a interchain token on a destination chain.
     * @param tokenId The ID of the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     * @param distributor The distributor address for the token
     * @param destinationChain The destination chain where the token will be deployed
     * @param gasValue The amount of gas to be paid for the transaction
     */
    function _deployRemoteInterchainToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) internal {
        // slither-disable-next-line unused-return
        validTokenManagerAddress(tokenId);

        // slither-disable-next-line reentrancy-events
        emit RemoteInterchainTokenDeploymentInitialized(tokenId, name, symbol, decimals, distributor, operator, destinationChain, gasValue);

        bytes memory payload = abi.encode(SELECTOR_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, distributor, operator);
        _callContract(destinationChain, payload, gasValue);
    }

    /**
     * @notice Deploys a token manager
     * @param tokenId The ID of the token
     * @param tokenManagerType The type of the token manager to be deployed
     * @param params Additional parameters for the token manager deployment
     */
    function _deployTokenManager(bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) internal {
        // slither-disable-next-line controlled-delegatecall
        (bool success, bytes memory returnData) = tokenManagerDeployer.delegatecall(
            abi.encodeWithSelector(ITokenManagerDeployer.deployTokenManager.selector, tokenId, tokenManagerType, params)
        );
        if (!success) revert TokenManagerDeploymentFailed(returnData);

        address tokenManager;
        assembly {
            tokenManager := mload(add(returnData, 0x20))
        }

        // slither-disable-next-line reentrancy-events
        emit TokenManagerDeployed(tokenId, tokenManager, tokenManagerType, params);
    }

    /**
     * @notice Compute the salt for a interchain token deployment.
     * @param tokenId The ID of the token
     * @return salt The computed salt for the token deployment
     */
    function _getInterchainTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        return keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, tokenId));
    }

    /**
     * @notice Deploys a interchain token.
     * @param tokenId The ID of the token
     * @param distributorBytes The distributor address for the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    function _deployInterchainToken(
        bytes32 tokenId,
        bytes memory distributorBytes,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (address tokenAddress_) {
        bytes32 salt = _getInterchainTokenSalt(tokenId);
        address tokenManagerAddress_ = tokenManagerAddress(tokenId);

        address distributor;
        if (bytes(distributorBytes).length != 0) distributor = distributorBytes.toAddress();

        // slither-disable-next-line controlled-delegatecall
        (bool success, bytes memory returnData) = interchainTokenDeployer.delegatecall(
            abi.encodeWithSelector(
                IInterchainTokenDeployer.deployInterchainToken.selector,
                salt,
                tokenManagerAddress_,
                distributor,
                name,
                symbol,
                decimals
            )
        );
        if (!success) {
            revert InterchainTokenDeploymentFailed(returnData);
        }

        assembly {
            tokenAddress_ := mload(add(returnData, 0x20))
        }

        // slither-disable-next-line reentrancy-events
        emit InterchainTokenDeployed(tokenId, tokenAddress_, distributor, name, symbol, decimals);
    }

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
     * @notice Transmit a callContractWithInterchainToken for the given tokenId. Only callable by a token manager.
     * @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
     * @param sourceAddress the address where the token is coming from, which will also be used for reimburment of gas.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the destinationAddress for the interchainTransfer.
     * @param amount the amount of token to give.
     * @param metadata the data to be passed to the destiantion.
     */
    function _transmitInterchainTransfer(
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

            payload = abi.encode(SELECTOR_RECEIVE_TOKEN, tokenId, sourceAddress.toBytes(), destinationAddress, amount);

            _callContract(destinationChain, payload, msg.value);
            return;
        }
        uint32 version;
        (version, metadata) = _decodeMetadata(metadata);
        if (version > 0) revert InvalidMetadataVersion(version);

        // slither-disable-next-line reentrancy-events
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, metadata);

        payload = abi.encode(SELECTOR_RECEIVE_TOKEN_WITH_DATA, tokenId, sourceAddress.toBytes(), destinationAddress, amount, metadata);

        _callContract(destinationChain, payload, msg.value);
    }
}
