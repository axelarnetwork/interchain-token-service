// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ExpressCallHandler } from '../../utils/ExpressCallHandler.sol';

contract ExpressCallHandlerTest is ExpressCallHandler {
    address public lastPoppedExpressCaller;

    function setExpressReceiveToken(bytes32 commandId, bytes calldata payload, address expressCaller) external {
        _setExpressCaller(commandId, keccak256(payload), expressCaller);
    }

    function popExpressReceiveToken(bytes32 commandId, bytes calldata payload) external {
        lastPoppedExpressCaller = _popExpressCaller(commandId, keccak256(payload));
    }
}
