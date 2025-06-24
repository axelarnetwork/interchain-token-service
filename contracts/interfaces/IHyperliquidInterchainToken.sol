// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainToken } from './IInterchainToken.sol';

/**
 * @title IHyperliquidInterchainToken interface
 * @notice Interface for HyperliquidInterchainToken with deployer management functionality
 */
interface IHyperliquidInterchainToken is IInterchainToken {
    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployer The address of the deployer
     */
    function getDeployer() external view returns (address deployer);

    /**
     * @notice Allows updating the deployer address
     * @dev No authorization logic - this should be handled by the calling contract
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external;
}
