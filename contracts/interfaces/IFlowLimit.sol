// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title FlowLimit Interface
 * @notice Interface for flow limit logic for interchain token transfers.
 */
interface IFlowLimit {
    error FlowLimitExceeded(uint256 limit, uint256 flowAmount, address tokenManager);
    error FlowAdditionOverflow(uint256 flowToAdd, uint256 flowAmount, address tokenManager);
    error FlowLimitOverflow(uint256 flowLimit, uint256 flowToCompare, address tokenManager);

    event FlowLimitSet(bytes32 indexed tokenId, address operator, uint256 flowLimit_);

    /**
     * @notice Returns the current flow limit.
     * @return flowLimit_ The current flow limit value.
     */
    function flowLimit() external view returns (uint256 flowLimit_);

    /**
     * @notice Returns the current flow out amount.
     * @return flowOutAmount_ The current flow out amount.
     */
    function flowOutAmount() external view returns (uint256 flowOutAmount_);

    /**
     * @notice Returns the current flow in amount.
     * @return flowInAmount_ The current flow in amount.
     */
    function flowInAmount() external view returns (uint256 flowInAmount_);
}
