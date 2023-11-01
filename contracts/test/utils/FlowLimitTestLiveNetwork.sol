// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IFlowLimit } from '../../interfaces/IFlowLimit.sol';

contract FlowLimitTestLiveNetwork is IFlowLimit {
    uint256 internal constant FLOW_LIMIT_SLOT = 0x201b7a0b7c19aaddc4ce9579b7df8d2db123805861bc7763627f13e04d8af42f;
    uint256 internal constant PREFIX_FLOW_OUT_AMOUNT = uint256(keccak256('flow-out-amount'));
    uint256 internal constant PREFIX_FLOW_IN_AMOUNT = uint256(keccak256('flow-in-amount'));
    bytes32 public constant TOKEN_ID = 0x0;

    uint256 internal constant EPOCH_TIME = 60;

    function flowLimit() public view returns (uint256 flowLimit) {
        assembly {
            flowLimit := sload(FLOW_LIMIT_SLOT)
        }
    }

    function _setFlowLimit(uint256 flowLimit) internal {
        assembly {
            sstore(FLOW_LIMIT_SLOT, flowLimit)
        }

        emit FlowLimitSet(TOKEN_ID, msg.sender, flowLimit);
    }

    function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_OUT_AMOUNT, epoch)));
    }

    function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_IN_AMOUNT, epoch)));
    }

    function flowOutAmount() external view returns (uint256 flowOutAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowOutSlot(epoch);

        assembly {
            flowOutAmount := sload(slot)
        }
    }

    function flowInAmount() external view returns (uint256 flowInAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowInSlot(epoch);

        assembly {
            flowInAmount := sload(slot)
        }
    }

    function _addFlow(uint256 flowLimit, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal {
        uint256 flowToAdd;
        uint256 flowToCompare;

        assembly {
            flowToAdd := sload(slotToAdd)
            flowToCompare := sload(slotToCompare)
        }

        uint256 maxFlowLimit = flowToCompare + flowLimit;
        uint256 netFlowAmount = flowToAdd + flowAmount;
        if (netFlowAmount > maxFlowLimit) revert FlowLimitExceeded(maxFlowLimit, netFlowAmount);
        if (flowAmount > flowLimit) revert FlowLimitExceeded(flowLimit, flowAmount);

        assembly {
            sstore(slotToAdd, add(flowToAdd, flowAmount))
        }
    }

    function _addFlowOut(uint256 flowOutAmount) internal {
        uint256 flowLimit = flowLimit();
        if (flowLimit == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowOutSlot(epoch);
        uint256 slotToCompare = _getFlowInSlot(epoch);

        _addFlow(flowLimit, slotToAdd, slotToCompare, flowOutAmount);
    }

    function _addFlowIn(uint256 flowInAmount) internal {
        uint256 flowLimit = flowLimit();
        if (flowLimit == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowInSlot(epoch);
        uint256 slotToCompare = _getFlowOutSlot(epoch);

        _addFlow(flowLimit, slotToAdd, slotToCompare, flowInAmount);
    }

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
