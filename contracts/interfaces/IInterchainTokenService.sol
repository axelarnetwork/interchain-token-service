// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';

interface IInterchainTokenService is ITokenManagerType {
    event Sending(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event SendingWithData(
        bytes32 tokenId,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        address indexed from,
        bytes data
    );
    event Receiving(bytes32 tokenId, string sourceChain, address indexed destinationAddress, uint256 indexed amount);
    event ReceivingWithData(
        bytes32 tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        address indexed from,
        bytes data
    );
    event TokenManagerDeployed(
        bytes32 indexed tokenId,
        address indexed tokenManagerAddress,
        address indexed admin,
        bytes32 salt,
        bytes params
    );
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenId, string destinationChain, uint256 gasValue);

    function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function getCustomTokenId(address admin, bytes32 salt) external view returns (bytes32 tokenId);

    function registerCanonicalToken(address tokenAddress) external returns (bytes32 tokenId);

    function registerCanonicalTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable;

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable;

    function registerCustomToken(bytes32 salt, TokenManagerType tokenManagerType, bytes calldata params) external;

    function registerRemoteCustomTokens(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues
    ) external payable;

    function registerCustomTokenAndDeployRemote(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata remoteParams,
        uint256[] calldata gasValues
    ) external;
}
