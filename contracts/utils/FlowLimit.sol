// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IFlowLimit } from '../interfaces/IFlowLimit.sol';

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

contract FlowLimit is IFlowLimit {
    // uint256(keccak256('flow-limit')) - 1
    uint256 internal constant FLOW_LIMIT_SLOT = 0x201b7a0b7c19aaddc4ce9579b7df8d2db123805861bc7763627f13e04d8af42f;
    // uint256(keccak256('prefix-flow-out-amount')) - 1
    uint256 internal constant PREFIX_FLOW_OUT_AMOUNT = 0x6f1a35c5e40326475a796c94e031a3851775a946476d26a171e62b16123d615e;
    // uint256(keccak256('prefix-flow-in-amount')) - 1
    uint256 internal constant PREFIX_FLOW_IN_AMOUNT = 0x1d21c88109f56b2bdc45ba0dd60835c2b1e30aadf9a5b957a10ff785333e8b62;

    uint256 internal constant EPOCH_TIME = 6 hours;

    function getFlowLimit() public view returns (uint256 flowLimit) {
        assembly {
            flowLimit := sload(FLOW_LIMIT_SLOT)
        }
    }

    function _setFlowLimit(uint256 flowLimit) internal {
        assembly {
            sstore(FLOW_LIMIT_SLOT, flowLimit)
        }
    }

    function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_OUT_AMOUNT, epoch)));
    }

    function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_IN_AMOUNT, epoch)));
    }

    function getFlowOutAmount() external view returns (uint256 flowOutAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowOutSlot(epoch);
        assembly {
            flowOutAmount := sload(slot)
        }
    }

    function getFlowInAmount() external view returns (uint256 flowInAmount) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowInSlot(epoch);
        assembly {
            flowInAmount := sload(slot)
        }
    }

    function _addFlow(uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal {
        uint256 flowLimit = getFlowLimit();
        if (flowLimit == 0) return;
        uint256 flowToAdd;
        uint256 flowToCompare;
        assembly {
            flowToAdd := sload(slotToAdd)
            flowToCompare := sload(slotToCompare)
        }
        if (flowToAdd + flowAmount > flowToCompare + flowLimit) revert FlowLimitExceeded();
        assembly {
            sstore(slotToAdd, add(flowToAdd, flowAmount))
        }
    }

    function _addFlowOut(uint256 flowOutAmount) internal {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowOutSlot(epoch);
        uint256 slotToCompare = _getFlowInSlot(epoch);
        _addFlow(slotToAdd, slotToCompare, flowOutAmount);
    }

    function _addFlowIn(uint256 flowInAmount) internal {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowInSlot(epoch);
        uint256 slotToCompare = _getFlowOutSlot(epoch);
        _addFlow(slotToAdd, slotToCompare, flowInAmount);
    }
}
