// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { TokenManagerDeployer } from '../utils/TokenManagerDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

import { ExpressCallHandler } from '../utils/ExpressCallHandler.sol';
import { Pausable } from '../utils/Pausable.sol';

contract InterchainTokenService is
    IInterchainTokenService,
    TokenManagerDeployer,
    AxelarExecutable,
    Upgradable,
    ExpressCallHandler,
    Pausable
{
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;

    address public immutable implementationLockUnlock;
    address public immutable implementationMintBurn;
    address public immutable implementationCanonical;
    address public immutable implementationLiquidityPool;
    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('its-custom-token-id');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_ID = keccak256('its-cacnonical-token-id');

    uint256 private constant SELECTOR_SEND_TOKEN = 1;
    uint256 private constant SELECTOR_SEND_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;

    // keccak256('interchain-token-service')-1
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    constructor(
        address deployer_,
        address bytecodeServer_,
        address gateway_,
        address gasService_,
        address linkerRouter_,
        address[] memory tokenManagerImplementations,
        string memory chainName_
    ) TokenManagerDeployer(deployer_, bytecodeServer_) AxelarExecutable(gateway_) {
        if (linkerRouter_ == address(0) || gasService_ == address(0)) revert ZeroAddress();
        linkerRouter = ILinkerRouter(linkerRouter_);
        gasService = IAxelarGasService(gasService_);

        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        // use a loop for the zero address checks?
        if (tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)] == address(0)) revert ZeroAddress();
        implementationLockUnlock = tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)];
        if (tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)] == address(0)) revert ZeroAddress();
        implementationMintBurn = tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)];
        if (tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)] == address(0)) revert ZeroAddress();
        implementationCanonical = tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)];
        if (tokenManagerImplementations[uint256(TokenManagerType.LIQUIDITY_POOL)] == address(0)) revert ZeroAddress();
        implementationLiquidityPool = tokenManagerImplementations[uint256(TokenManagerType.LIQUIDITY_POOL)];

        // let's store it as a string, so if another user/contract queries it, it's sensical
        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /*******\
    MODIFIERS
    \*******/

    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
    }

    modifier onlyTokenManager(bytes32 tokenId) {
        if (msg.sender != getTokenManagerAddress(tokenId)) revert NotTokenManager();
        _;
    }

    /*****\
    GETTERS
    \*****/

    function getChainName() public view returns (string memory name) {
        name = chainName.toTrimmedString();
    }

    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if (ITokenManagerProxy(tokenManagerAddress).tokenId() != tokenId) revert TokenManagerNotDeployed(tokenId);
    }

    // There are two ways to cacluate a tokenId, one is for pre-existing tokens, and anyone can do this for a token once.
    function getCanonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_ID, chainNameHash, tokenAddress));
    }

    // The other is by providing a salt, and your address (msg.sender) is used for the calculation.
    function getCustomTokenId(address admin, bytes32 salt) public pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, admin, salt));
    }

    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress) {
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.CANONICAL) {
            return implementationCanonical;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.LIQUIDITY_POOL) {
            return implementationLiquidityPool;
        }
    }


    function getParamsLockUnlock(bytes calldata admin, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress);
    }

    function getParamsMintBurn(bytes calldata admin, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress);
    }

    function getParamsCanonical(bytes calldata admin, string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals, uint256 mintAmount) public pure returns (bytes memory params)  {
        params = abi.encode(admin, tokenName, tokenSymbol, tokenDecimals, mintAmount);
    }

    function getParamsLiquidityPool(bytes calldata admin, address tokenAddress, address liquidityPoolAddress) public pure returns (bytes memory params) {
        params = abi.encode(admin, tokenAddress, liquidityPoolAddress);
    }

    /************\
    USER FUNCTIONS
    \************/

    function registerCanonicalToken(address tokenAddress) external notPaused returns (bytes32 tokenId) {
        (, string memory tokenSymbol, ) = _validateToken(tokenAddress);
        if (gateway.tokenAddresses(tokenSymbol) == tokenAddress) revert GatewayToken();
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this).toBytes(), tokenAddress));
    }

    function registerCanonicalTokenAndDeployRemoteCanonicalTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable notPaused returns (bytes32 tokenId) {
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this).toBytes(), tokenAddress));
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        bytes memory params = abi.encode('', tokenName, tokenSymbol, tokenDecimals);
        _deployRemoteCanonicalTokens(tokenId, params, destinationChains, gasValues);
    }

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) public payable notPaused {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();
        if (getCanonicalTokenId(tokenAddress) != tokenId) revert NotCanonicalToken();
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        bytes memory params = abi.encode('', tokenName, tokenSymbol, tokenDecimals);
        _deployRemoteCanonicalTokens(tokenId, params, destinationChains, gasValues);
    }

    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes memory params) public notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    function deployRemoteCustomTokenManagers(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployRemoteCustomTokens(tokenId, destinationChains, tokenManagerTypes, params, gasValues);
    }

    function deployCustomTokenManagerAndDeployRemote(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata remoteParams,
        uint256[] calldata gasValues
    ) external payable notPaused {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
        _deployRemoteCustomTokens(tokenId, destinationChains, tokenManagerTypes, remoteParams, gasValues);
    }

    function deployCustomTokenManagerLockUnlock(bytes32 salt, bytes calldata admin, address tokenAddress) external {
        bytes memory params = getParamsLockUnlock(admin, tokenAddress);
        deployCustomTokenManager(salt, TokenManagerType.LOCK_UNLOCK, params);
    }
    function deployCustomTokenManagerMintBurn(bytes32 salt, bytes calldata admin, address tokenAddress) external {
        bytes memory params = getParamsMintBurn(admin, tokenAddress);
        deployCustomTokenManager(salt, TokenManagerType.MINT_BURN, params);
    }
    function deployCustomTokenManagerCanonical(bytes32 salt, bytes calldata admin, string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals, uint256 mintAmount) external {
        bytes memory params = getParamsCanonical(admin, tokenName, tokenSymbol, tokenDecimals, mintAmount);
        deployCustomTokenManager(salt, TokenManagerType.CANONICAL, params);
    }
    function deployCustomTokenManagerLiquidityPool(bytes32 salt, bytes calldata admin, address tokenAddress, address liquidityPoolAddress) external {
        bytes memory params = getParamsLiquidityPool(admin, tokenAddress, liquidityPoolAddress);
        deployCustomTokenManager(salt, TokenManagerType.LIQUIDITY_POOL, params);
    }


    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) external notPaused {
        address caller = msg.sender;
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        IERC20 token = IERC20(tokenManager.tokenAddress());
        uint256 balance = token.balanceOf(destinationAddress);
        SafeTokenTransferFrom.safeTransferFrom(token, caller, destinationAddress, amount);
        amount = token.balanceOf(destinationAddress) - balance;
        _setExpressSendToken(tokenId, destinationAddress, amount, sendHash, caller);

        emit ExpressExecuted(tokenId, destinationAddress, amount, sendHash, caller);
    }

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
        _setExpressSendTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, caller);
        _passData(destinationAddress, tokenId, sourceChain, sourceAddress, amount, data);
        emit ExpressExecutedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, caller);
    }

    /*********************\
    TOKEN MANAGER FUNCTIONS
    \*********************/

    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount));
        bytes memory payload = abi.encode(SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount, sendHash);
        _callContract(destinationChain, payload, msg.value, sourceAddress);
        emit TokenSent(tokenId, destinationChain, destinationAddress, amount, sendHash);
    }

    function transmitSendTokenWithData(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount));
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

    function transmitSendTokenWithToken(
        bytes32 tokenId,
        string calldata symbol,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount));
        bytes memory payload = abi.encode(SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount, sendHash);
        _callContractWithToken(destinationChain, symbol, amount, payload, sourceAddress);
        emit TokenSent(tokenId, destinationChain, destinationAddress, amount, sendHash);
    }

    function transmitSendTokenWithDataWithToken(
        bytes32 tokenId,
        string memory symbol,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes memory data
    ) external payable onlyTokenManager(tokenId) notPaused {
        bytes32 sendHash = keccak256(abi.encode(tokenId, block.number, amount));
        {
            bytes memory sourceAddressBytes = sourceAddress.toBytes();
            bytes memory payload = abi.encode(
                SELECTOR_SEND_TOKEN_WITH_DATA,
                tokenId,
                destinationAddress,
                amount,
                sourceAddressBytes,
                data,
                sendHash
            );
            _callContractWithToken(destinationChain, symbol, amount, payload, sourceAddress);
        }
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, data, sendHash);
    }

    function approveGateway(bytes32 tokenId, address tokenAddress) external onlyTokenManager(tokenId) {
        IERC20Named(tokenAddress).approve(address(gateway), type(uint256).max);
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    function setFlowLimit(bytes32 tokenId, uint256 flowLimit) external onlyOwner {
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        tokenManager.setFlowLimit(flowLimit);
    }

    function setPaused(bool paused) external onlyOwner {
        _setPaused(paused);
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
        }
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata /*symbol*/,
        uint256 /*amount*/
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        _execute(sourceChain, sourceAddress, payload);
    }

    function _processSendTokenPayload(string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount, bytes32 sendHash) = abi.decode(
            payload,
            (uint256, bytes32, bytes, uint256, bytes32)
        );
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenManager tokenManager = ITokenManager(getValidTokenManagerAddress(tokenId));
        address expressCaller = _popExpressSendToken(tokenId, destinationAddress, amount, sendHash);
        if (expressCaller == address(0)) {
            amount = tokenManager.giveToken(destinationAddress, amount);
            emit TokenReceived(tokenId, sourceChain, destinationAddress, amount, sendHash);
        } else {
            amount = tokenManager.giveToken(expressCaller, amount);
            emit ExpressExecutionFulfilled(tokenId, destinationAddress, amount, sendHash, expressCaller);
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
            address expressCaller = _popExpressSendTokenWithData(
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
                emit ExpressExecutionWithDataFulfilled(
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationAddress,
                    amount,
                    data,
                    sendHash,
                    expressCaller
                );
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

    function _callContractWithToken(
        string calldata destinationChain,
        string memory symbol,
        uint256 amount,
        bytes memory payload,
        address refundTo
    ) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        uint256 gasValue = msg.value;
        if (gasValue > 0) {
            gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                refundTo
            );
        }
        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
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

    function _deployRemoteCanonicalTokens(
        bytes32 tokenId,
        bytes memory params,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) internal {
        uint256 length = destinationChains.length;
        if (length != gasValues.length) revert LengthMismatch();
        for (uint256 i = 0; i < length; ++i) {
            _deployRemoteTokenManager(tokenId, destinationChains[i], gasValues[i], TokenManagerType.CANONICAL, params);
        }
    }

    function _deployRemoteCustomTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues
    ) internal {
        uint256 length = destinationChains.length;
        if (length != gasValues.length || length != tokenManagerTypes.length || length != params.length) revert LengthMismatch();
        for (uint256 i = 0; i < length; ++i) {
            _deployRemoteTokenManager(tokenId, destinationChains[i], gasValues[i], tokenManagerTypes[i], params[i]);
        }
    }

    function _callContract(string memory destinationChain, bytes memory payload, uint256 gasValue) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _callContractWithToken(string memory destinationChain, string calldata symbol, uint256 amount, bytes memory payload) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        uint256 gasValue = msg.value;
        if (gasValue > 0) {
            gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                msg.sender
            );
        }
        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }

    function _passData(
        address destinationAddress,
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        uint256 amount,
        bytes memory data
    ) internal {
        IInterchainTokenExecutable(destinationAddress).exectuteWithInterchainToken(sourceChain, sourceAddress, data, tokenId, amount);
    }
}
