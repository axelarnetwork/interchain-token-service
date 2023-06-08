// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

contract ExpressCallHandler is IExpressCallHandler {
    mapping(bytes32 => address) private expressGiveToken;
    mapping(bytes32 => address) private expressGiveTokenWithData;

    function _getExpressSendTokenKey(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(tokenId, destinationAddress, amount, sendHash));
    }

    function _getExpressSendTokenWithDataKey(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 sendHash
    ) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash));
    }

    function _setExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    ) internal {
        expressGiveToken[_getExpressSendTokenKey(tokenId, destinationAddress, amount, sendHash)] = expressCaller;
        emit ExpressExecuted(tokenId, destinationAddress, amount, sendHash, expressCaller);
    }

    function _setExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash,
        address expressCaller
    ) internal {
        expressGiveTokenWithData[
            _getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash)
        ] = expressCaller;
        emit ExpressExecutedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, expressCaller);
    }

    function getExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) public view returns (address expressCaller) {
        expressCaller = expressGiveToken[_getExpressSendTokenKey(tokenId, destinationAddress, amount, sendHash)];
    }

    function getExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) public view returns (address expressCaller) {
        expressCaller = expressGiveTokenWithData[
            _getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash)
        ];
    }

    function _popExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        bytes32 key = _getExpressSendTokenKey(tokenId, destinationAddress, amount, sendHash);
        expressCaller = expressGiveToken[key];
        if (expressCaller != address(0)) {
            expressGiveToken[key] = address(0);
            emit ExpressExecutionFulfilled(tokenId, destinationAddress, amount, sendHash, expressCaller);
        }
    }

    function _popExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        bytes32 key = _getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
        expressCaller = expressGiveTokenWithData[key];
        if (expressCaller != address(0)) {
            expressGiveTokenWithData[key] = address(0);
            emit ExpressExecutionWithDataFulfilled(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                sendHash,
                expressCaller
            );
        }
    }
}
