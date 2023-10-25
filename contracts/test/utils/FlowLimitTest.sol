// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FlowLimit } from '../../utils/FlowLimit.sol';

contract FlowLimitTest is FlowLimit {
    bytes32 public constant TOKEN_ID = 0x0;

    function setFlowLimit(uint256 flowLimit) external {
        _setFlowLimit(flowLimit, TOKEN_ID);
    }

    function addFlowIn(uint256 flowInAmount) external {
        _addFlowIn(flowInAmount, TOKEN_ID);
    }

    function addFlowOut(uint256 flowOutAmount) external {
        _addFlowOut(flowOutAmount, TOKEN_ID);
    }
}
