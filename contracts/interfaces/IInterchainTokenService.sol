// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol';

import { IExpressCallHandler } from './IExpressCallHandler.sol';
import { ITokenManagerDeployer } from './ITokenManagerDeployer.sol';
import { ITokenManagerType } from './ITokenManagerType.sol';
import { IPausable } from './IPausable.sol';
import { IMulticall } from './IMulticall.sol';

interface IInterchainTokenService is ITokenManagerType, IExpressCallHandler, IAxelarExecutable, IPausable, IMulticall {
    // more generic error
    error ZeroAddress();
    error LengthMismatch();
    error InvalidTokenManagerImplementation();
    error NotRemoteService();
    error TokenManagerDoesNotExist(bytes32 tokenId);
    error NotTokenManager();
    error ExecuteWithInterchainTokenFailed(address contractAddress);
    error NotCanonicalTokenManager();
    error GatewayToken();
    error TokenManagerDeploymentFailed();
    error StandardizedTokenDeploymentFailed();
    error DoesNotAcceptExpressExecute(address contractAddress);
    error SelectorUnknown();
    error InvalidMetadataVersion(uint32 version);
    error AlreadyExecuted(bytes32 commandId);

    event TokenSent(bytes32 tokenId, string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event TokenSentWithData(
        bytes32 tokenId,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        address indexed sourceAddress,
        bytes data
    );
    event TokenReceived(bytes32 indexed tokenId, string sourceChain, address indexed destinationAddress, uint256 indexed amount);
    event TokenReceivedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        bytes sourceAddress,
        bytes data
    );
    event RemoteTokenManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue,
        TokenManagerType indexed tokenManagerType,
        bytes params
    );
    event RemoteCanonicalStandardizedTokenAndManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue
    );
    event RemoteCustomStandardizedTokenAndManagerDeploymentInitialized(
        bytes32 indexed tokenId,
        string destinationChain,
        uint256 indexed gasValue
    );
    event TokenManagerDeployed(bytes32 tokenId, TokenManagerType tokenManagerType, bytes params);
    event StandardizedTokenDeployed(
        bytes32 tokenId,
        string name,
        string symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo,
        address tokenAddress
    );

    function tokenManagerDeployer() external view returns (address);

    function standardizedTokenDeployer() external view returns (address);

    function getChainName() external view returns (string memory name);

    function getTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenManagerAddress);

    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getCustomStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getCanonicalStandardizedTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function isCanonical(bytes32 tokenId) external view returns (bool);

    function getCanonicalStandardizedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    function getCustomTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    function getParamsLockUnlock(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    function getParamsMintBurn(bytes memory operator, address tokenAddress) external pure returns (bytes memory params);

    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) external pure returns (bytes memory params);

    function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId);

    function deployRemoteCanonicalToken(bytes32 tokenId, string calldata destinationChain, uint256 gasValue) external payable;

    function deployCustomTokenManager(bytes32 salt, TokenManagerType tokenManagerType, bytes memory params) external payable;

    function deployRemoteCustomTokenManager(
        bytes32 salt,
        string calldata destinationChain,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        uint256 gasValue
    ) external payable;

    function deployAndRegisterCanonicalStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable;

    // This deploys a standardized token, mints mintAmount to msg.sender.
    // Then if the distributor is the tokenManagerAddress for the tokenId calculated based on the salt then it deploys a Mint/Burn tokenManager, or it deploys a Lock/Unlock one otherwise.
    function deployAndRegisterCustomStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable;

    function deployAndRegisterRemoteCustomStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bytes memory distributor,
        bytes memory operator,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable;

    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress);

    function transmitSendToken(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    function setFlowLimit(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external;

    function getFlowLimit(bytes32 tokenId) external view returns (uint256 flowLimit);

    function getFlowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount);

    function getFlowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount);

    function setPaused(bool paused) external;

    /**
     * @notice Uses the caller's tokens to fullfill a sendCall ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param commandId the commandId calculated from the event at the sourceChain.
     */
    function expressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external;

    /**
     * @notice Uses the caller's tokens to fullfill a callContractWithInterchainToken ahead of time. Use this only if you have detected an outgoing sendToken that matches the parameters passed here.
     * @param tokenId the tokenId of the TokenManager used.
     * @param sourceChain the name of the chain where the call came from.
     * @param sourceAddress the caller of callContractWithInterchainToken.
     * @param destinationAddress the destinationAddress for the sendToken.
     * @param amount the amount of token to give.
     * @param data the data to be passed to destinationAddress after giving them the tokens specified.
     * @param commandId the commandId calculated from the event at the sourceChain.
     */
    function expressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) external;
}
