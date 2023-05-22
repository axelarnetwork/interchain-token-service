// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenDeployer } from './ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';
import { ITokenLinkerDeployer } from '../interfaces/ITokenLinkerDeployer.sol';

interface IInterchainTokenRegistry is ITokenLinkerDeployer {
    error TokenServiceZeroAddress();
    error NotTokenLinker();

    event Sending(string destinationChain, bytes destinationAddress, uint256 indexed amount, bytes32 indexed sendHash);
    event SendingWithData(
        address sourceAddress,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        bytes data,
        bytes32 indexed sendHash
    );
    event Receiving(bytes32 indexed tokenLinkerId, address indexed destinationAddress, uint256 amount, bytes32 sendHash);
    event ReceivingWithData(
        bytes32 indexed tokenLinkerId,
        string sourceChain,
        address indexed destinationAddress,
        uint256 amount,
        bytes from,
        bytes data,
        bytes32 indexed sendHash,
        bool executionSuccessful
    );

    event TokenRegistered(bytes32 indexed tokenLinkerId, TokenLinkerType tokenLinkerType, bytes params, address indexed tokenLinkerAddress);
    event TokenLinkerDeployed(bytes32 tokenLinkerId, address tokenLinkerAddress);
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenLinkerId, string destinationChain, uint256 gasValue);

    function sendToken(
        bytes32 tokenLinkerId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable;

    function sendTokenWithData(
        bytes32 tokenLinkerId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function getImplementation(TokenLinkerType tokenLinkerType) external view returns (address impl);
}
