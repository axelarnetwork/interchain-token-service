// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenDeployer } from './ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';

interface IInterchainTokenService {
    error TokenServiceZeroAddress();
    error TransferFailed();
    error TransferFromFailed();
    error MintFailed();
    error BurnFailed();
    error NotOriginToken();
    error NotRegistered();
    error AlreadyRegistered();
    error NotGatewayToken();
    error GatewayToken();
    error LengthMismatch();
    error NotSelf();
    error TokenDeploymentFailed();
    error ExceedMintLimit(bytes32 tokenId);
    error ExecutionFailed();
    error AlreadyExpressExecuted();
    error InvalidSelector();

    event Sending(string destinationChain, bytes destinationAddress, uint256 indexed amount, bytes32 indexed sendHash);
    event SendingWithData(
        address sourceAddress,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        bytes data,
        bytes32 indexed sendHash
    );
    event Receiving(bytes32 indexed tokenId, address indexed destinationAddress, uint256 amount, bytes32 sendHash);
    event ReceivingWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 amount,
        bytes from,
        bytes data,
        bytes32 indexed sendHash,
        bool executionSuccessful
    );

    event TokenRegistered(bytes32 indexed tokenId, address indexed tokenAddress, bool native, bool gateway, bool remoteGateway);
    event TokenDeployed(address indexed tokenAddress, string name, string symbol, uint8 decimals, address indexed owner);
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenId, string destinationChain, uint256 gasValue);

    function getTokenData(bytes32 tokenId) external view returns (bytes32 tokenData);

    function isOriginToken(bytes32 tokenId) external view returns (bool);

    function isGatewayToken(bytes32 tokenId) external view returns (bool);

    function isRemoteGatewayToken(bytes32 tokenId) external view returns (bool);

    function getGatewayTokenSymbol(bytes32 tokenId) external view returns (string memory symbol);

    function getOriginalChain(bytes32 tokenId) external view returns (string memory origin);

    function isCustomInterchainToken(bytes32 tokenId) external view returns (bool);

    function getTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function tokenDeployer() external view returns (ITokenDeployer);

    function linkerRouter() external view returns (ILinkerRouter);

    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getOriginTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function getInterchainTokenId(address sender, bytes32 salt) external view returns (bytes32);

    function getCustomInterchainTokenId(address tokenAddress) external pure returns (bytes32);

    function getDeploymentAddress(address sender, bytes32 salt) external view returns (address deployment);

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function registerOriginToken(address tokenAddress) external returns (bytes32 tokenId);

    function registerSelfAsInterchainToken() external returns (bytes32 tokenId);

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable;

    function getTokenMintLimit(bytes32 tokenId) external view returns (uint256 mintLimit);

    function setTokenMintLimit(bytes32 tokenId, uint256 mintLimit) external;

    function setSelfMintLimit(uint256 mintLimit) external;

    function sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata to, uint256 amount) external payable;

    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata to,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function registerOriginGatewayToken(string calldata symbol) external returns (bytes32 tokenId);

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external;

    // These two are meant to be called by tokens to have this service facilitate the token transfers for them.
    function sendSelf(address from, string calldata destinationChain, bytes calldata to, uint256 amount) external payable;

    function callContractWithSelf(
        address from,
        string calldata destinationChain,
        bytes calldata to,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function expressExecute(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 sendHash) external;

    function expressExecuteWithToken(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external;
}
