// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IFlowLimit } from '../interfaces/IFlowLimit.sol';

/**
 * @title FlowLimit
 * @notice Implements flow limit logic for interchain token transfers.
 * @dev This contract implements low-level assembly for optimization purposes.
 */
contract FlowLimit is IFlowLimit {
    // uint256(keccak256('flow-limit')) - 1
    uint256 internal constant FLOW_LIMIT_SLOT = 0x201b7a0b7c19aaddc4ce9579b7df8d2db123805861bc7763627f13e04d8af42f;
    uint256 internal constant PREFIX_FLOW_OUT_AMOUNT = uint256(keccak256('flow-out-amount'));
    uint256 internal constant PREFIX_FLOW_IN_AMOUNT = uint256(keccak256('flow-in-amount'));

    uint256 internal constant EPOCH_TIME = 6 hours;

    /**
     * @notice Returns the current flow limit.
     * @return flowLimit_ The current flow limit value.
     */
    function flowLimit() public view returns (uint256 flowLimit_) {
        assembly {
            flowLimit_ := sload(FLOW_LIMIT_SLOT)
        }
    }

    /**
     * @notice Internal function to set the flow limit.
     * @param flowLimit_ The value to set the flow limit to. Must not be set to `uint256.max`.
     * Only the operator can set the flow limit for their own token; however, an incorrect setting
     * may result in a denial of service due to potential arithmetic underflow or overflow.
     * @param tokenId The id of the token to set the flow limit for.
     */
    function _setFlowLimit(uint256 flowLimit_, bytes32 tokenId) internal {
        assembly {
            sstore(FLOW_LIMIT_SLOT, flowLimit_)
        }

        emit FlowLimitSet(tokenId, msg.sender, flowLimit_);
    }

    /**
     * @notice Returns the slot which is used to get the flow out amount for a specific epoch.
     * @param epoch The epoch to get the flow out amount for.
     * @return slot The slot to get the flow out amount from.
     */
    function _getFlowOutSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_OUT_AMOUNT, epoch)));
    }

    /**
     * @dev Returns the slot which is used to get the flow in amount for a specific epoch.
     * @param epoch The epoch to get the flow in amount for.
     * @return slot The slot to get the flow in amount from.
     */
    function _getFlowInSlot(uint256 epoch) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_FLOW_IN_AMOUNT, epoch)));
    }

    /**
     * @notice Returns the current flow out amount.
     * @return flowOutAmount_ The current flow out amount.
     */
    function flowOutAmount() external view returns (uint256 flowOutAmount_) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowOutSlot(epoch);

        assembly {
            flowOutAmount_ := sload(slot)
        }
    }

    /**
     * @notice Returns the current flow in amount.
     * @return flowInAmount_ The current flow in amount.
     */
    function flowInAmount() external view returns (uint256 flowInAmount_) {
        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slot = _getFlowInSlot(epoch);

        assembly {
            flowInAmount_ := sload(slot)
        }
    }

    /**
     * @notice Adds a flow amount while ensuring it does not exceed the flow limit.
     * @param flowLimit_ The current flow limit value.
     * @param slotToAdd The slot to add the flow to.
     * @param slotToCompare The slot to compare the flow against.
     * @param flowAmount The flow amount to add.
     */
    function _addFlow(uint256 flowLimit_, uint256 slotToAdd, uint256 slotToCompare, uint256 flowAmount) internal {
        uint256 flowToAdd;
        uint256 flowToCompare;

        assembly {
            flowToAdd := sload(slotToAdd)
            flowToCompare := sload(slotToCompare)
        }

        // Overflow checks for flowToAdd + flowAmount and flowToCompare + flowLimit_
        if (flowToAdd > type(uint256).max - flowAmount) revert FlowAdditionOverflow(flowAmount, flowToAdd, address(this));
        if (flowToCompare > type(uint256).max - flowLimit_) revert FlowLimitOverflow(flowLimit_, flowToCompare, address(this));

        if (flowToAdd + flowAmount > flowToCompare + flowLimit_)
            revert FlowLimitExceeded((flowToCompare + flowLimit_), flowToAdd + flowAmount, address(this));
        if (flowAmount > flowLimit_) revert FlowLimitExceeded(flowLimit_, flowAmount, address(this));

        assembly {
            sstore(slotToAdd, add(flowToAdd, flowAmount))
        }
    }

    /**
     * @notice Adds a flow out amount.
     * @param flowOutAmount_ The flow out amount to add.
     */
    function _addFlowOut(uint256 flowOutAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowOutSlot(epoch);
        uint256 slotToCompare = _getFlowInSlot(epoch);

        _addFlow(flowLimit_, slotToAdd, slotToCompare, flowOutAmount_);
    }

    /**
     * @notice Adds a flow in amount.
     * @param flowInAmount_ The flow in amount to add.
     */
    function _addFlowIn(uint256 flowInAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / EPOCH_TIME;
        uint256 slotToAdd = _getFlowInSlot(epoch);
        uint256 slotToCompare = _getFlowOutSlot(epoch);

        _addFlow(flowLimit_, slotToAdd, slotToCompare, flowInAmount_);
    }
}
