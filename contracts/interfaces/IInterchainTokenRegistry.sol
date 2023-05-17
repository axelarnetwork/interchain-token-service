// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenDeployer } from './ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

interface IInterchainTokenRegistry {
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

    event TokenRegistered(bytes32 indexed tokenId, address indexed tokenAddress);
    event TokenDeployed(address indexed tokenAddress, string name, string symbol, uint8 decimals, address indexed owner);
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenId, string destinationChain, uint256 gasValue);

    function sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable;
}
