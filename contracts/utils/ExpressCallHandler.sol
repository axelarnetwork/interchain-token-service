// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

contract ExpressCallHandler is IExpressCallHandler{
    mapping(bytes32 => address) private expressGiveToken;
    mapping(bytes32 => address) private expressGiveTokenWithData;
    address public immutable interchainTokenServiceAddress;

    constructor(address interchainTokenServiceAddress_) {
        interchainTokenServiceAddress = interchainTokenServiceAddress_;
    }

    modifier onlyService() {
        if(msg.sender != interchainTokenServiceAddress) revert NotService();
        _;
    }

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
        bytes calldata data,
        bytes32 sendHash
    ) internal pure returns (bytes32 key) {
        key = keccak256(
            abi.encode(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash)
        );
    }

    function setExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    ) external onlyService() {
        expressGiveToken[_getExpressSendTokenKey(tokenId, destinationAddress, amount, sendHash)] = expressCaller;
    }

    function setExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash,
        address expressCaller
    ) external onlyService() {
        expressGiveTokenWithData[_getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash)] = expressCaller;
    }

    function getExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) external view returns (address expressCaller) {
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
    ) external view returns (address expressCaller) {
        expressCaller = expressGiveTokenWithData[_getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash)];
    }
    function popExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) external onlyService returns (address expressCaller) {
        bytes32 key = _getExpressSendTokenKey(tokenId, destinationAddress, amount, sendHash);
        expressCaller = expressGiveToken[key];
        if(expressCaller != address(0)) {
            expressGiveToken[key] = address(0);
        }
    }

    function popExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) external onlyService returns (address expressCaller) {
        bytes32 key = _getExpressSendTokenWithDataKey(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
        expressCaller = expressGiveTokenWithData[key];
        if(expressCaller != address(0)) {
            expressGiveTokenWithData[key] = address(0);
        }
    }
}