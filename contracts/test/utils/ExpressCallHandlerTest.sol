// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ExpressCallHandler } from '../../utils/ExpressCallHandler.sol';

contract ExpressCallHandlerTest is ExpressCallHandler {
    address public lastPoppedExpressCaller;

    function setExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId,
        address expressCaller
    ) external {
        _setExpressReceiveToken(tokenId, destinationAddress, amount, commandId, expressCaller);
    }

    function setExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId,
        address expressCaller
    ) external {
        _setExpressReceiveTokenWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
    }

    function popExpressReceiveToken(bytes32 tokenId, address destinationAddress, uint256 amount, bytes32 commandId) external {
        lastPoppedExpressCaller = _popExpressReceiveToken(tokenId, destinationAddress, amount, commandId);
    }

    function popExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 commandId
    ) external {
        lastPoppedExpressCaller = _popExpressReceiveTokenWithData(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
    }
}
