// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenDeployer } from './ITokenDeployer.sol';

interface IInterchainTokenService {
    error TokenServiceZeroAddress();
    error TransferFailed();
    error TransferFromFailed();
    error MintFailed();
    error BurnFailed();
    error NotOriginToken();
    error AlreadyRegistered();
    error NotGatewayToken();
    error GatewayToken();
    error LengthMismatch();
    error NotSelf();
    error TokenDeploymentFailed();
    error ExceedMintLimit(bytes32 tokenId);
    error ExecutionFailed();

    event Sending(string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event SendingWithData(string destinationChain, bytes destinationAddress, uint256 indexed amount, address indexed from, bytes data);
    event Receiving(string sourceChain, address indexed destinationAddress, uint256 indexed amount);
    event ReceivingWithData(
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        address indexed from,
        bytes data
    );
    event TokenRegistered(bytes32 indexed tokenId, address indexed tokenAddress, bool native, bool gateway, bool remoteGateway);
    event TokenDeployed(address indexed tokenAddress, string name, string symbol, uint8 decimals, address indexed owner);
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenId, string destinationChain, uint256 gasValue);

    function getTokenData(bytes32 tokenId) external view returns (bytes32 tokenData);

    function getOriginalChain(bytes32 tokenId) external view returns (string memory origin);

    function getTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function tokenDeployer() external view returns (ITokenDeployer);

    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getOriginTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function getInterchainTokenId(address sender, bytes32 salt) external view returns (bytes32);

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

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable;

    function sendToken(bytes32 tokenId, string memory destinationChain, bytes memory to, uint256 amount) external payable;

    function callContractWithInterchainToken(
        bytes32 tokenId,
        string memory destinationChain,
        bytes memory to,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function registerOriginGatewayToken(string calldata symbol) external returns (bytes32 tokenId);

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external;

    // These two are meant to be called by tokens to have this service facilitate the token transfers for them.
    function sendSelf(address from, string memory destinationChain, bytes memory to, uint256 amount) external payable;

    function callContractWithSelf(
        address from,
        string memory destinationChain,
        bytes memory to,
        uint256 amount,
        bytes calldata data
    ) external payable;
}
