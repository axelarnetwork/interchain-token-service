// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FlowLimit } from '../../utils/FlowLimit.sol';

contract TestFlowLimitLiveNetwork is FlowLimit {
    bytes32 public constant TOKEN_ID = 0x0;

    /**
     * @notice Override of the epochTime function for testing
     * @return The epoch time in seconds for testing (60 seconds)
     */
    function epochTime() internal pure override returns (uint256) {
        return 60;
    }

    function setFlowLimit(uint256 flowLimit_) external {
        _setFlowLimit(flowLimit_, TOKEN_ID);
    }

    function addFlowIn(uint256 flowInAmount_) external {
        _addFlowIn(flowInAmount_);
    }

    function addFlowOut(uint256 flowOutAmount_) external {
        _addFlowOut(flowOutAmount_);
    }
}
