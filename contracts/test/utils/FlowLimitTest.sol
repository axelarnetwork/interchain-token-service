// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FlowLimit } from '../../utils/FlowLimit.sol';

contract FlowLimitTest is FlowLimit {
    function setFlowLimit(uint256 flowLimit) external {
        _setFlowLimit(flowLimit);
    }

    function addFlowIn(uint256 flowInAmount) external {
        _addFlowIn(flowInAmount);
    }

    function addFlowOut(uint256 flowOutAmount) external {
        _addFlowOut(flowOutAmount);
    }
}
