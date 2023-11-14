// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IFlowLimit } from '../../interfaces/IFlowLimit.sol';

contract TestFlowLimitLiveNetwork is IFlowLimit {
    uint256 internal constant FLOW_LIMIT_SLOT = 0x201b7a0b7c19aaddc4ce9579b7df8d2db123805861bc7763627f13e04d8af42f;
    uint256 internal constant PREFIX_FLOW_OUT_AMOUNT = uint256(keccak256('flow-out-amount'));
    uint256 internal constant PREFIX_FLOW_IN_AMOUNT = uint256(keccak256('flow-in-amount'));
    bytes32 public constant TOKEN_ID = 0x0;

    uint256 internal constant EPOCH_TIME = 60;

    function flowLimit() public view returns (uint256 flowLimit_) {
        assembly {
            flowLimit_ := sload(FLOW_LIMIT_SLOT)
        }
    }

    function _setFlowLimit(uint256 flowLimit_) internal {
        assembly {
            sstore(FLOW_LIMIT_SLOT, flowLimit_)
        }

        emit FlowLimitSet(TOKEN_ID, msg.sender, flowLimit_);
    }

    function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_OUT_AMOUNT, epoch)));
    }

    function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_IN_AMOUNT, epoch)));
    }

    function flowOutAmount() external view returns (uint256 flowOutAmount_) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowOutSlot(epoch);

        assembly {
            flowOutAmount_ := sload(slot)
        }
    }

    function flowInAmount() external view returns (uint256 flowInAmount_) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowInSlot(epoch);

        assembly {
            flowInAmount_ := sload(slot)
        }
    }

    function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal {
        uint256 flowToAdd;
        uint256 flowToCompare;

        assembly {
            flowToAdd := sload(slotToAdd)
            flowToCompare := sload(slotToCompare)
        }

        uint256 maxFlowLimit = flowToCompare + flowLimit_;
        uint256 netFlowAmount = flowToAdd + flowAmount;
        if (netFlowAmount > maxFlowLimit) revert FlowLimitExceeded(maxFlowLimit, netFlowAmount);
        if (flowAmount > flowLimit_) revert FlowLimitExceeded(flowLimit_, flowAmount);

        assembly {
            sstore(slotToAdd, add(flowToAdd, flowAmount))
        }
    }

    function _addFlowOut(uint256 flowOutAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowOutSlot(epoch);
        uint256 slotToCompare = _getFlowInSlot(epoch);

        _addFlow(flowLimit_, slotToAdd, slotToCompare, flowOutAmount_);
    }

    function _addFlowIn(uint256 flowInAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowInSlot(epoch);
        uint256 slotToCompare = _getFlowOutSlot(epoch);

        _addFlow(flowLimit_, slotToAdd, slotToCompare, flowInAmount_);
    }

    function setFlowLimit(uint256 flowLimit_) external {
        _setFlowLimit(flowLimit_);
    }

    function addFlowIn(uint256 flowInAmount_) external {
        _addFlowIn(flowInAmount_);
    }

    function addFlowOut(uint256 flowOutAmount_) external {
        _addFlowOut(flowOutAmount_);
    }
}
