// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { TokenManagerDeployer } from '../utils/TokenManagerDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

contract InterchainTokenService is IInterchainTokenService, TokenManagerDeployer, AxelarExecutable {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using AddressBytesUtils for bytes;

    address public immutable implementationLockUnlock;
    address public immutable implementationMintBurn;
    address public immutable implementationCanonical;
    address public immutable implementationGateway;
    ILinkerRouter public immutable linkerRouter;
    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    bytes32 internal constant PREFIX_CUSTOM_TOKEN_ID = keccak256('itl-custom-token-id');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_ID = keccak256('itl-cacnonical-token-id');

    uint256 private constant SELECTOR_SEND_TOKEN = 1;
    uint256 private constant SELECTOR_SEND_TOKEN_WITH_DATA = 2;
    uint256 private constant SELECTOR_DEPLOY_TOKEN_MANAGER = 3;

    constructor(
        address deployer_,
        address bytecodeServer_,
        address gateway_,
        address linkerRouter_,
        address[] memory tokenManagerImplementations,
        string memory chainName_
    ) TokenManagerDeployer(deployer_, bytecodeServer_) AxelarExecutable(gateway_) {
        if (linkerRouter_ == address(0)) revert TokenServiceZeroAddress();
        linkerRouter = ILinkerRouter(linkerRouter_);
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

    // solhint-disable-next-line no-empty-blocks
    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress) {
        tokenManagerAddress = getTokenManagerAddress(tokenId);
        if(ITokenManagerProxy(tokenManagerAddress).tokenId() != tokenId) revert TokenManagerNotDeployed(tokenId);
    }

    // There are two ways to cacluate a tokenId, one is for pre-existing tokens, and anyone can do this for a token once.
    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_ID, chainNameHash, tokenAddress));
    }

    // The other is by providing a salt, and your address (msg.sender) is used for the calculation.
    function getCustomTokenId(address admin, bytes32 salt) external pure returns (bytes32 tokenId) {
        tokenId = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_ID, admin, salt));
    }

    // solhint-disable-next-line no-empty-blocks
    function registerCanonicalToken(address tokenAddress) external returns (bytes32 tokenId) {
        // TODO: implement
    }

    function registerCanonicalTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable returns (bytes32 tokenId) {
        // TODO: implement
    }

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes calldata params) external {
        // TODO: implement
    }

    function deployRemoteCustomTokenManagers(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    function deployCustomTokenManagerAndDeployRemote(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata remoteParams,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
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
}
