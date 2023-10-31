// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ExpressCallHandler } from '../../utils/ExpressCallHandler.sol';

contract ExpressCallHandlerTest is ExpressCallHandler {
    address public lastPoppedExpressCaller;

    function getExpressReceiveToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external view returns (address expressCaller) {
        return _getExpressExecutor(commandId, sourceChain, sourceAddress, keccak256(payload));
    }

    function setExpressReceiveToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        address expressCaller
    ) external {
        _setExpressExecutor(commandId, sourceChain, sourceAddress, keccak256(payload), expressCaller);
    }

    function popExpressReceiveToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        lastPoppedExpressCaller = _popExpressExecutor(commandId, sourceChain, sourceAddress, keccak256(payload));
    }
}
