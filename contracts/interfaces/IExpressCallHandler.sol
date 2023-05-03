// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IExpressCallHandler {
    error NotService();

    event ExpressExecuted(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    );
    event ExpressExecutionFulfilled(
        bytes32 indexed tokenId,
        address indexed destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    );

    event ExpressExecutedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 amount,
        bytes data,
        bytes32 indexed sendHash,
        bool executionSuccessful,
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
        bool executionSuccessful,
        address expressCaller
    );

    function setExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    ) external;

    function setExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash,
        address expressCaller
    ) external;

    function getExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) external view returns (address expressCaller);

    function getExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external view returns (address expressCaller);

    function popExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) external returns (address expressCaller);

    function popExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external returns (address expressCaller);
}
