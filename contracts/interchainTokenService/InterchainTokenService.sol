// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';

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

contract InterchainTokenService is IInterchainTokenService, TokenManagerDeployer, AxelarExecutable, Upgradable {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;

    address public immutable implementationLockUnlock;
    address public immutable implementationMintBurn;
    address public immutable implementationCanonical;
    address public immutable implementationGateway;
    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('itl-custom-token-id');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_ID = keccak256('itl-cacnonical-token-id');

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
        if (linkerRouter_ == address(0) || gasService_ == address(0)) revert TokenServiceZeroAddress();
        linkerRouter = ILinkerRouter(linkerRouter_);
        gasService = IAxelarGasService(gasService_);
        if (tokenManagerImplementations.length != 4) revert LengthMismatch();
        if (tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)] == address(0)) revert TokenServiceZeroAddress();
        implementationLockUnlock = tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)];
        if (tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)] == address(0)) revert TokenServiceZeroAddress();
        implementationMintBurn = tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)];
        if (tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)] == address(0)) revert TokenServiceZeroAddress();
        implementationCanonical = tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)];
        if (tokenManagerImplementations[uint256(TokenManagerType.GATEWAY)] == address(0)) revert TokenServiceZeroAddress();
        implementationGateway = tokenManagerImplementations[uint256(TokenManagerType.GATEWAY)];

        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) revert NotRemoteService();
        _;
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

    function registerCanonicalToken(address tokenAddress) external returns (bytes32 tokenId) {
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this), tokenAddress));
    }

    function registerCanonicalTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId) {
        tokenId = getCanonicalTokenId(tokenAddress);
        _deployTokenManager(tokenId, TokenManagerType.LOCK_UNLOCK, abi.encode(address(this), tokenAddress));
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        bytes memory params = abi.encode(address(0), tokenName, tokenSymbol, tokenDecimals);
        _deployRemoteCanonicalTokens(tokenId, params, destinationChains, gasValues);
    }

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) public payable {
        address tokenAddress = getValidTokenManagerAddress(tokenId);
        tokenAddress = ITokenManager(tokenAddress).tokenAddress();
        (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = _validateToken(tokenAddress);
        bytes memory params = abi.encode(address(0), tokenName, tokenSymbol, tokenDecimals);
        _deployRemoteCanonicalTokens(tokenId, params, destinationChains, gasValues);
    }

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address admin,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        bytes memory params = abi.encode(admin, tokenName, tokenSymbol, decimals);
        _deployTokenManager(tokenId, TokenManagerType.CANONICAL, params);
        _deployRemoteCanonicalTokens(tokenId, params, destinationChains, gasValues);
    }

    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes calldata params) external {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
    }

    function deployRemoteCustomTokenManagers(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues
    ) external payable {
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
    ) external payable {
        bytes32 tokenId = getCustomTokenId(msg.sender, salt);
        _deployTokenManager(tokenId, tokenManagerType, params);
        _deployRemoteCustomTokens(tokenId, destinationChains, tokenManagerTypes, remoteParams, gasValues);
    }

    function getImplementation(TokenManagerType tokenManagerType) external view returns (address tokenManagerAddress) {
        if (tokenManagerType == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (tokenManagerType == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (tokenManagerType == TokenManagerType.CANONICAL) {
            return implementationCanonical;
        } else if (tokenManagerType == TokenManagerType.GATEWAY) {
            return implementationGateway;
        }
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SELECTOR_SEND_TOKEN) {
            _proccessSendTokenPayload(sourceChain, payload);
        } else if (selector == SELECTOR_SEND_TOKEN_WITH_DATA) {
            _proccessSendTokenWithDataPayload(sourceChain, payload);
        } else if (selector == SELECTOR_DEPLOY_TOKEN_MANAGER) {
            _proccessDeployTokenManagerPayload(payload);
        }
    }

    function _proccessSendTokenPayload(string calldata sourceChain, bytes calldata payload) internal {
        (, bytes32 tokenId, bytes memory destinationAddressBytes, uint256 amount, bytes32 sendHash) = abi.decode(
            payload,
            (uint256, bytes32, bytes, uint256, bytes32)
        );
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenManager tokenManager = ITokenManager(getTokenManagerAddress(tokenId));
        amount = tokenManager.giveToken(destinationAddress, amount);
        emit Receiving(tokenId, sourceChain, destinationAddress, amount, sendHash);
    }

    function _proccessSendTokenWithDataPayload(string calldata sourceChain, bytes calldata payload) internal {
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
        amount = tokenManager.giveToken(destinationAddress, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = destinationAddress.call(
            abi.encodeWithSelector(
                IInterchainTokenExecutable.exectuteWithInterchainToken.selector,
                tokenId,
                sourceChain,
                sourceAddress,
                amount,
                data
            )
        );
        emit ReceivingWithData(tokenId, sourceChain, destinationAddress, amount, sourceAddress, data, success, sendHash);
    }

    function _proccessDeployTokenManagerPayload(bytes calldata payload) internal {
        (, bytes32 tokenId, TokenManagerType tokenManagerType, bytes memory params) = abi.decode(
            payload,
            (uint256, bytes32, TokenManagerType, bytes)
        );
        _deployTokenManager(tokenId, tokenManagerType, params);
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
        _callContract(destinationChain, payload, gasValue);
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
}
