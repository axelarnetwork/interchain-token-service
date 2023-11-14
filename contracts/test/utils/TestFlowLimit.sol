// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FlowLimit } from '../../utils/FlowLimit.sol';

contract TestFlowLimit is FlowLimit {
    error Invalid();

    bytes32 public constant TOKEN_ID = 0x0;

    string public placeholder;

    constructor() {
        if (FLOW_LIMIT_SLOT != uint256(keccak256('flow-limit')) - 1) revert Invalid();
    }

    function setFlowLimit(uint256 flowLimit) external {
        _setFlowLimit(flowLimit, TOKEN_ID);
    }

    function addFlowIn(uint256 flowInAmount) external {
        _addFlowIn(flowInAmount);
    }

    function addFlowOut(uint256 flowOutAmount) external {
        _addFlowOut(flowOutAmount);
    }
}
