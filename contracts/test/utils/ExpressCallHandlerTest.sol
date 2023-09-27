// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ExpressCallHandler } from '../../utils/ExpressCallHandler.sol';

contract ExpressCallHandlerTest is ExpressCallHandler {
    address public lastPoppedExpressCaller;

    function setExpressReceiveToken(bytes calldata payload, bytes32 commandId, address expressCaller) external {
        _setExpressReceiveToken(payload, commandId, expressCaller);
    }

    function popExpressReceiveToken(bytes calldata payload, bytes32 commandId) external {
        lastPoppedExpressCaller = _popExpressReceiveToken(payload, commandId);
    }
}
