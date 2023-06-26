// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IExpressCallHandler {
    error AlreadyExpressCalled();
    error SameDestinationAsCaller();

    event ExpressReceived(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 indexed sendHash,
        address expressCaller
    );
    event ExpressExecutionFulfilled(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 indexed sendHash,
        address expressCaller
    );

    event ExpressReceivedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes data,
        bytes32 indexed sendHash,
        address expressCaller
    );
    event ExpressExecutionWithDataFulfilled(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes data,
        bytes32 indexed sendHash,
        address expressCaller
    );

    function getExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) external view returns (address expressCaller);

    function getExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external view returns (address expressCaller);
}
