// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ExpressCallHandler } from '../utils/ExpressCallHandler.sol';
import { Pausable } from '../utils/Pausable.sol';
import { Multicall } from '../utils/Multicall.sol';

/// @title The Interchain Token Service
/// @notice This contract is responsible for facilitating cross chain token transfers.
/// It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for cross chain transfers to happen.
/// @dev The only storage used here is for ExpressCalls
contract InterchainTokenService is IInterchainTokenService, AxelarExecutable, Upgradable, ExpressCallHandler, Pausable, Multicall {
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

    // TODO: For contract Id, we can stick to not using the -1 convention
    // keccak256('interchain-token-service')
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    /// @dev All of the varaibles passed here are stored as immutable variables.
    /// @param tokenManagerDeployer_ the address of the TokenManagerDeployer.
    /// @param standardizedTokenDeployer_ the address of the StandardizedTokenDeployer.
    /// @param gateway_ the address of the AxelarGateway.
    /// @param gasService_ the address of the AxelarGasService.
    /// @param linkerRouter_ the address of the LinkerRouter.
    /// @param tokenManagerImplementations this need to have exactly 3 implementations in the following order: Lock/Unlock, mint/burn and then liquidity pool.
    /// @param chainName_ the name of the current chain.
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

        if (tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)] == address(0)) revert ZeroAddress();
        implementationLockUnlock = tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)];
        if (tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)] == address(0)) revert ZeroAddress();
        implementationMintBurn = tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)];
        if (tokenManagerImplementations[uint256(TokenManagerType.LIQUIDITY_POOL)] == address(0)) revert ZeroAddress();
        implementationLiquidityPool = tokenManagerImplementations[uint256(TokenManagerType.LIQUIDITY_POOL)];

        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /*******\
    MODIFIERS
    \*******/

    /// @notice This modifier is used to ensure that only a remote InterchainTokenService can _execute this one.
    /// @param sourceChain the source of the contract call.
    /// @param sourceAddress the address that the call came from.
    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    /// @notice This modifier is used to ensure certain functions can only be called by TokenManagers.
    /// @param tokenId the `tokenId` of the TokenManager trying to perform the call.
    modifier onlyTokenManager(bytes32 tokenId) {
        if (msg.sender != getTokenManagerAddress(tokenId)) revert NotTokenManager();
        _;
    }

    /*****\
    GETTERS
    \*****/

    /// @notice Getter for the chain name.
    /// @return name the name of the chain
    function getChainName() public view returns (string memory name) {
        name = chainName.toTrimmedString();
    }

    /// @notice Calculates the address of a TokenManager from a specific tokenId. The TokenManager does not need to exist already.
    /// @param tokenId the tokenId.
    /// @return tokenManagerAddress deployement address of the TokenManager.
    function getTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /// @notice Returns the address of a TokenManager from a specific tokenId. The TokenManager needs to exist already.
    /// @param tokenId the tokenId.
    /// @return tokenManagerAddress deployement address of the TokenManager.
    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if (ITokenManagerProxy(tokenManagerAddress).tokenId() != tokenId) revert TokenManagerNotDeployed(tokenId);
    }

    /// @notice Returns the address of the token that an existing tokenManager points to.
    /// @param tokenId the tokenId.
    /// @return tokenAddress the address of the token.
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        address tokenManagerAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenManagerAddress).tokenAddress();
    }

    /// @notice Returns the address of the standardized token that would be deployed with a given tokenId. The token does not need to exist.
    /// @param tokenId the tokenId.
    /// @return tokenAddress the address of the standardized token.
    function getStandardizedTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        tokenId = _getStandardizedTokenSalt(tokenId);
        tokenAddress = deployer.deployedAddress(address(this), tokenId);
    }

    /// @notice Calculates the tokenId that would correspond to a canonical link for a given token. This will depend on what chain it is called from, unlike custom tokenIds.
    /// @param tokenAddress the address of the token.
    /// @return tokenId the tokenId that the canonical TokenManager would get (or has gotten) for the token.
    function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_ID, chainNameHash, tokenAddress));
    }

    /// @notice Calculates the tokenId that would correspond to a custom link for a given deployer with a specified salt. This will not depend on what chain it is called from, unlike canonical tokenIds.
    /// @param sender the address of the TokenManager deployer.
    /// @param salt the salt that the deployer uses for the deployment.
    /// @return tokenId the tokenId that the custom TokenManager would get (or has gotten).
    function getCustomTokenId(address sender, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, sender, salt));
    }

    /// @notice Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies to figure out their implementations
    /// @param tokenManagerType the type of the TokenManager.
    /// @return tokenManagerAddress the address of the TokenManagerImplementation.
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

    /// @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
    /// @param admin the admin of the TokenManager.
    /// @param tokenAddress the token to be managed.
    /// @return params the resulting params to be passed to custom TokenManager deployments.
    function getParamsLockUnlock(bytes memory admin, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress);
    }

    /// @notice Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.
    /// @param admin the admin of the TokenManager.
    /// @param tokenAddress the token to be managed.
    /// @return params the resulting params to be passed to custom TokenManager deployments.
    function getParamsMintBurn(bytes memory admin, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress);
    }

    /// @notice Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.
    /// @param admin the admin of the TokenManager.
    /// @param tokenAddress the token to be managed.
    /// @param liquidityPoolAddress the liquidity pool to be used to store the bridged tokens.
    /// @return params the resulting params to be passed to custom TokenManager deployments.
    function getParamsLiquidityPool(
        bytes memory admin,
        address tokenAddress,
        address liquidityPoolAddress
    ) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress, liquidityPoolAddress);
    }

    /************\
    USER FUNCTIONS
    \************/

    /// @notice Used to register canonical tokens. Caller does not matter.
    /// @param tokenAddress the token to be bridged.
    /// @return tokenId the tokenId that was used for this canonical token.
    function registerCanonicalToken(address tokenAddress) external payable notPaused returns (bytes32 tokenId) {
        (, string memory tokenSymbol, ) = _validateToken(tokenAddress);
        if (gateway.tokenAddresses(tokenSymbol) == tokenAddress) revert GatewayToken();
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this).toBytes(), tokenAddress));
    }

    /// @notice Used to deploy remote TokenManagers and standardized tokens for a canonical token. This needs to be called from the chain that registered the canonical token, and anyone can call it.
    /// @param tokenId the tokenId of the canonical token.
    /// @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
    /// @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call
    /// @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) public payable notPaused {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();
        if (getCanonicalTokenId(tokenAddress) != tokenId) revert NotCanonicalTokenManager();
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        _deployRemoteStandardizedToken(tokenId, tokenName, tokenSymbol, tokenDecimals, '', '', destinationChain, gasValue);
    }

    /// @notice Used to deploy custom TokenManagers with the specified salt. Different callers would result in different tokenIds.
    /// @param salt the salt to be used.
    /// @param tokenManagerType the type of TokenManager to be deployed.
    /// @param params the params that will be used to initialize the TokenManager.
    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes memory params) public payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    /// @notice Used to deploy remote custom TokenManagers.
    /// @param salt the salt to be used.
    /// @param destinationChain the name of the chain to deploy the TokenManager and standardized token to.
    /// @param tokenManagerType the type of TokenManager to be deployed.
    /// @param params the params that will be used to initialize the TokenManager.
    /// @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call
    /// @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
    function deployRemoteCustomTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteTokenManager(tokenId, destinationChain, gasValue, tokenManagerType, params);
    }

    /// @notice Used to deploy a standardized token alongside a TokenManager. If the `distributor` is the address of the TokenManager (which can be calculated ahead of time) then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
    /// @param salt the salt to be used.
    /// @param name the name of the token to be deployed.
    /// @param symbol the symbol of the token to be deployed.
    /// @param decimals the decimals of the token to be deployed.
    /// @param mintAmount the amount of token to be mint during deployment to msg.sender.
    /// @param distributor the address that will be able to mint and burn the deployed token.
    function deployAndRegisterStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) public payable {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, mintAmount, msg.sender);
        address tokenManagerAddress = getTokenManagerAddress(tokenId);
        TokenManagerType tokenManagerType = distributor == tokenManagerAddress ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        _deployTokenManager(tokenId, tokenManagerType, abi.encode(msg.sender.toBytes(), tokenAddress));
    }

    /// @notice Used to deploy a standardized token alongside a TokenManager in another chain. If the `distributor` is empty bytes then a mint/burn TokenManager is used. Otherwise a lock/unlcok TokenManager is used.
    /// @param salt the salt to be used.
    /// @param name the name of the token to be deployed.
    /// @param symbol the symbol of the token to be deployed.
    /// @param decimals the decimals of the token to be deployed.
    /// @param distributor the address that will be able to mint and burn the deployed token.
    /// @param destinationChain the name of the destination chain to deploy to.
    /// @param gasValue the amount of native tokens to be used to pay for gas for the remote deployment. At least the amount specified needs to be passed to the call
    /// @dev `gasValue` exists because this function can be part of a multicall involving multiple functions that could make remote contract calls.
    function deployAndRegisterRemoteStandardizedTokens(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory admin,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteStandardizedToken(tokenId, name, symbol, decimals, distributor, admin, destinationChain, gasValue);
    }

    // TODO: pause check isn't needed for this since it's just passing tokens through, so we can save some gas
    // TODO: Add commandID to help express vs execute reorder protection, i.e check if commandID is already executed
    /// @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
    /// @param tokenId the tokenId of the TokenManager used.
    /// @param destinationAddress the destinationAddress for the sendToken.
    /// @param amount the amount of token to give.
    /// @param sendHash the sendHash detected at the sourceChain.
    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) external notPaused {
        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());
        uint256 balance = token.balanceOf(destinationAddress);
        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);
        amount = token.balanceOf(destinationAddress) - balance;
        _setExpressReceiveToken(tokenId, destinationAddress, amount, sendHash, caller);
    }

    // TODO: express receive with data should be opt-in since the data is opaque and might be high value
    // TODO: I think we should have an InterchainTokenExpressExecutable interface that apps can add/customize. This method can just call that, and the app can track the express relayer.
    // TODO: Alternatively, ITS tracks it and queries the contract to check for opt-in status (default is opt out), at the cost of more gas usage and less flexibility, but some more trust.
    // TODO: similar comment on forwarding commandID
    // TODO: similar comment on pause
    /// @notice Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
    /// @param tokenId the tokenId of the TokenManager used.
    /// @param sourceChain the name of the chain where the call came from.
    /// @param sourceAddress the caller of callContractWithInterchainToken.
    /// @param destinationAddress the destinationAddress for the sendToken.
    /// @param amount the amount of token to give.
    /// @param data the data to be passed to destinationAddress after giving them the tokens specified.
    /// @param sendHash the sendHash detected at the sourceChain.
    function expressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external notPaused {
        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());
        uint256 balance = token.balanceOf(destinationAddress);
        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);
        amount = token.balanceOf(destinationAddress) - balance;
        if (!IInterchainTokenExecutable(destinationAddress).acceptsExpressExecution())
            revert DoesNotAcceptExpressExecute(destinationAddress);
        _passData(destinationAddress, tokenId, sourceChain, sourceAddress, amount, data);
        _setExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, caller);
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    /// @notice Transmit a sendToken for the given tokenId.
    /// @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
    /// @param sourceAddress the address where the token is coming from, which will also be used for reimburment of gas.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the destinationAddress for the sendToken.
    /// @param amount the amount of token to give.
    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable onlyTokenManager(tokenId) notPaused {
        // TODO: what's the point of sendHash? block.number can't always enforce uniqueness
        // TODO: For express calls, I think we can accept the similar restriction as forecallable. For express with data, the app can provide unique data in payload if it wants.
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount, sourceAddress));
        bytes memory payload = abi.encode(SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount, sendHash);
        _callContract(destinationChain, payload, msg.value, sourceAddress);
        emit TokenSent(tokenId, destinationChain, destinationAddress, amount, sendHash);
    }

    /// @notice Transmit a sendTokenWithData for the given tokenId.
    /// @param tokenId the tokenId of the TokenManager (which must be the msg.sender).
    /// @param sourceAddress the address where the token is coming from, which will also be used for reimburment of gas.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the destinationAddress for the sendToken.
    /// @param amount the amount of token to give.
    /// @param data the data to be passed to the destiantion.
    function transmitSendTokenWithData(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount, sourceAddress));
        {
            bytes memory payload = abi.encode(
                SELECTOR_SEND_TOKEN_WITH_DATA,
                tokenId,
                destinationAddress,
                amount,
                sourceAddress.toBytes(),
                data,
                sendHash
            );
            _callContract(destinationChain, payload, msg.value, sourceAddress);
        }
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, data, sendHash);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    // TODO: allow passing a list of tokens and limits for convenience. a single owner tx is easier to prepare
    /// @notice Used to set a flow limit for a token manager that has the service as its admin.
    /// @param tokenIds an array of the token Ids of the tokenManagers to set the flow limit of.
    /// @param flowLimits and array of the flowLimit to set, identical in size to tokenIds.
    function setFlowLimit(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyOwner {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenIds[i]));
            tokenManager.setFlowLimit(flowLimits[i]);
        }
    }

    /// @notice Used to pause the entire service, as an emergency measure.
    /// @param paused what value to set paused to.
    function setPaused(bool paused) external onlyOwner {
        _setPaused(paused);
        emit PausedSet(paused);
    }

    /****************\
    INTERNAL FUNCTIONS
    \****************/

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

        // TODO: revert if selector is not recognized
    }

    function _processSendTokenPayload(string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount, bytes32 sendHash) = abi.decode(
            payload,
            (uint256, bytes32, bytes, uint256, bytes32)
        );
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        address expressCaller = _popExpressReceiveToken(tokenId, destinationAddress, amount, sendHash);
        if (expressCaller == address(0)) {
            amount = tokenManager.giveToken(destinationAddress, amount);
            emit TokenReceived(tokenId, sourceChain, destinationAddress, amount, sendHash);
        } else {
            amount = tokenManager.giveToken(expressCaller, amount);
        }
    }

    function _processSendTokenWithDataPayload(string calldata sourceChain, bytes calldata payload) internal {
        bytes32 tokenId;
        uint256 amount;
        bytes memory sourceAddress;
        bytes memory data;
        bytes32 sendHash;
        address destinationAddress;
        {
            bytes memory destinationAddressBytes;
            (, tokenId, destinationAddressBytes, amount, sourceAddress, data, sendHash) = abi.decode(
                payload,
                (uint256, bytes32, bytes, uint256, bytes, bytes, bytes32)
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
                sendHash
            );
            if (expressCaller != address(0)) {
                amount = tokenManager.giveToken(expressCaller, amount);
                return;
            }
        }
        amount = tokenManager.giveToken(destinationAddress, amount);
        _passData(destinationAddress, tokenId, sourceChain, sourceAddress, amount, data);
        emit TokenReceivedWithData(tokenId, sourceChain, destinationAddress, amount, sourceAddress, data, sendHash);
    }

    function _processDeployTokenManagerPayload(bytes calldata payload) internal {
        (, bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) = abi.decode(
            payload,
            (uint256, bytes32, TokenManagerType, bytes)
        );
        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    function _processDeployStandardizedTokenAndManagerPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenId,
            string memory name,
            string memory symbol,
            uint8 decimals,
            bytes memory distributorBytes,
            bytes memory adminBytes
        ) = abi.decode(payload, (uint256, bytes32, string, string, uint8, bytes, bytes));
        address tokenAddress = getStandardizedTokenAddress(tokenId);
        address distributor = distributorBytes.length > 0 ? distributorBytes.toAddress() : address(this);
        _deployStandardizedToken(tokenId, distributor, name, symbol, decimals, 0, distributor);
        TokenManagerType tokenManagerType = distributor == address(this) ? TokenManagerType.MINT_BURN : TokenManagerType.LOCK_UNLOCK;
        _deployTokenManager(
            tokenId,
            tokenManagerType,
            abi.encode(adminBytes.length == 0 ? address(this).toBytes() : adminBytes, tokenAddress)
        );
    }

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

    function _deployRemoteStandardizedToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory admin,
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
            admin
        );
        _callContract(destinationChain, payload, gasValue, msg.sender);
        emit RemoteStandardizedTokenAndManagerDeploymentInitialized(tokenId, destinationChain, gasValue);
    }

    function _passData(
        address destinationAddress,
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        uint256 amount,
        bytes memory data
    ) internal {
        IInterchainTokenExecutable(destinationAddress).executeWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
    }

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

    function _getStandardizedTokenSalt(bytes32 tokenId) internal pure returns (bytes32 salt) {
        return keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_SALT, tokenId));
    }

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
}
