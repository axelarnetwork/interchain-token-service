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

    uint256 private constant EPOCH_TIME = 6 hours;

    /**
     * @notice Returns the epoch duration for which the flow limit is applied
     * @return The epoch time
     */
    function epochTime() internal view virtual returns (uint256) {
        return EPOCH_TIME;
    }

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
     * @param flowLimit_ The value to set the flow limit to.
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
        uint256 epoch = block.timestamp / epochTime();
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
        uint256 epoch = block.timestamp / epochTime();
        uint256 slot = _getFlowInSlot(epoch);

        assembly {
            flowInAmount_ := sload(slot)
        }
    }

    /**
     * @notice Adds flow amount in the specified direction (in/out) for a token, and applies the flow limit.
     * @dev Reverts if:
     *  - Flow amount exceeds the flow limit
     *  - The flow in either direction exceeds `uint256::MAX`
     *  - Net flow (difference between in and out) exceeds the flow limit, i.e. |flow - reverse_flow| > flow_limit
     * @param flowSlot The storage slot for the current direction's flow (in or out).
     * @param reverseFlowSlot The storage slot for the opposite direction's flow.
     * @param flowAmount The amount of flow to add.
     * @param flowLimit_ The allowed maximum net flow during the epoch.
     */
    function _addFlow(uint256 flowSlot, uint256 reverseFlowSlot, uint256 flowAmount, uint256 flowLimit_) internal {
        uint256 flow;
        uint256 reverseFlow;

        assembly {
            flow := sload(flowSlot)
            reverseFlow := sload(reverseFlowSlot)
        }

        if (flowAmount > flowLimit_) {
            revert FlowAmountExceededLimit(flowLimit_, flowAmount, address(this));
        }

        if (flow > type(uint256).max - flowAmount) {
            revert FlowAmountOverflow(flowAmount, flow, address(this));
        }

        uint256 newFlow = flow + flowAmount;
        uint256 netFlow = newFlow >= reverseFlow ? newFlow - reverseFlow : reverseFlow - newFlow;

        if (netFlow > flowLimit_) {
            revert FlowLimitExceeded(flowLimit_, netFlow, address(this));
        }

        assembly {
            sstore(flowSlot, newFlow)
        }
    }

    /**
     * @notice Adds a flow out amount.
     * @param flowOutAmount_ The flow out amount to add.
     */
    function _addFlowOut(uint256 flowOutAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / epochTime();
        uint256 flowSlot = _getFlowOutSlot(epoch);
        uint256 reverseFlowSlot = _getFlowInSlot(epoch);

        _addFlow(flowSlot, reverseFlowSlot, flowOutAmount_, flowLimit_);
    }

    /**
     * @notice Adds a flow in amount.
     * @param flowInAmount_ The flow in amount to add.
     */
    function _addFlowIn(uint256 flowInAmount_) internal {
        uint256 flowLimit_ = flowLimit();
        if (flowLimit_ == 0) return;

        uint256 epoch = block.timestamp / epochTime();
        uint256 flowSlot = _getFlowInSlot(epoch);
        uint256 reverseFlowSlot = _getFlowOutSlot(epoch);

        _addFlow(flowSlot, reverseFlowSlot, flowInAmount_, flowLimit_);
    }
}
