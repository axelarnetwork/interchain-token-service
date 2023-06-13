// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol';

import { IExpressCallHandler } from './IExpressCallHandler.sol';
import { ITokenManagerDeployer } from './ITokenManagerDeployer.sol';
import { ITokenManagerType } from './ITokenManagerType.sol';
import { IPausable } from './IPausable.sol';

interface IInterchainTokenService is ITokenManagerType, IExpressCallHandler, IAxelarExecutable, IPausable {
    // more generic error
    error ZeroAddress();
    error LengthMismatch();
    error NotRemoteService();
    error TokenManagerNotDeployed(bytes32 tokenId);
    error NotTokenManager();
    error ExecuteWithInterchainTokenFailed(address contractAddress);
    error NotCanonicalTokenManager();
    error GatewayToken();
    error TokenManagerDeploymentFailed();
    error StandardizedTokenDeploymentFailed();

    event TokenSent(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 indexed amount, bytes32 sendHahs);
    event TokenSentWithData(
        bytes32 tokenId,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        address indexed sourceAddress,
        bytes data,
        bytes32 sendHash
    );
    event TokenReceived(
        bytes32 indexed tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        bytes32 sendHash
    );
    event TokenReceivedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        bytes sourceAddress,
        bytes data,
        bytes32 sendHash
    );
    event RemoteTokenManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue,
        TokenManagerType indexed tokenManagerType,
        bytes params
    );
    event RemoteStandardizedTokenAndManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue
    );
    event TokenManagerDeployed(bytes32 tokenId, TokenManagerType tokenManagerType, bytes params);
    event StandardizedTokenDeployed(bytes32 tokenId, string name, string symbol, uint8 decimals, uint256 mintAmount, address mintTo);

    function tokenManagerDeployer() external view returns (address);

    function standardizedTokenDeployer() external view returns (address);

    function getChainName() external view returns (string memory name);

    function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function getCustomTokenId(address admin, bytes32 salt) external view returns (bytes32 tokenId);

    function getParamsLockUnlock(bytes memory admin, address tokenAddress) external pure returns (bytes memory params);

    function getParamsMintBurn(bytes memory admin, address tokenAddress) external pure returns (bytes memory params);

    function getParamsLiquidityPool(
        bytes memory admin,
        address tokenAddress,
        address liquidityPoolAddress
    ) external pure returns (bytes memory params);

    function registerCanonicalToken(address tokenAddress) external returns (bytes32 tokenId);

    function registerCanonicalTokenAndDeployRemoteCanonicalTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable;

    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes memory params) external;

    function deployRemoteCustomTokenManagers(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues
    ) external payable;

    function deployCustomTokenManagerAndDeployRemote(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata remoteParams,
        uint256[] calldata gasValues
    ) external payable;

    // This deploys a standardized token, mints mintAmount to msg.sender.
    // Then if the distributor is the tokenManagerAddress for the tokenId calculated based on the salt then it deploys a Mint/Burn tokenManager, or it deploys a Lock/Unlock one otherwise.
    function deployAndRegisterStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external;

    function deployAndRegisterRemoteStandardizedTokens(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes calldata distributor,
        string calldata destinationChain
    ) external payable;

    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress);

    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable;

    function transmitSendTokenWithData(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function transmitSendTokenWithToken(
        bytes32 tokenId,
        string calldata symbol,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable;

    function transmitSendTokenWithDataWithToken(
        bytes32 tokenId,
        string memory symbol,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes memory data
    ) external payable;

    function approveGateway(bytes32 tokenId, address tokenAddress) external;

    function setFlowLimit(bytes32 tokenId, uint256 flowLimit) external;

    function setPaused(bool paused) external;
}
