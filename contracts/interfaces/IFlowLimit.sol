// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlowLimit {
    error FlowLimitExceeded(uint256 limit, uint256 flowAmount);

    event FlowLimitSet(uint256 flowLimit);

    /**
     * @notice Returns the current flow limit
     * @return flowLimit The current flow limit value
     */
    function getFlowLimit() external view returns (uint256 flowLimit);

    /**
     * @notice Returns the current flow out amount
     * @return flowOutAmount The current flow out amount
     */
    function getFlowOutAmount() external view returns (uint256 flowOutAmount);

    /**
     * @notice Returns the current flow in amount
     * @return flowInAmount The current flow in amount
     */
    function getFlowInAmount() external view returns (uint256 flowInAmount);
}
