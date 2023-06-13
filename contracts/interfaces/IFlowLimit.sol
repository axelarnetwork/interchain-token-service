// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IFlowLimit {
    error FlowLimitExceeded();

    function getFlowLimit() external view returns (uint256 flowLimit);

    function getFlowOutAmount() external view returns (uint256 flowOutAmount);

    function getFlowInAmount() external view returns (uint256 flowInAmount);
}
