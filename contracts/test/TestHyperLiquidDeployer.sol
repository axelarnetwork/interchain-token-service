// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HyperliquidDeployer } from '../interchain-token/HyperliquidDeployer.sol';

/**
 * @title TestHyperliquidDeployer
 * @notice Concrete implementation of HyperliquidDeployer for testing
 */
contract TestHyperliquidDeployer is HyperliquidDeployer {
    address public itsAddress;
    address public initialDeployer;

    constructor(address _itsAddress, address _initialDeployer) {
        itsAddress = _itsAddress;
        initialDeployer = _initialDeployer;
        _setDeployer(_initialDeployer);
    }

    /**
     * @notice Override updateDeployer with test-specific authorization logic
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override {
        // Test authorization: allow ITS address, current deployer, or initial deployer
        address currentDeployer = _deployer();
        if (msg.sender != itsAddress && msg.sender != currentDeployer && msg.sender != initialDeployer) {
            revert NotAuthorized();
        }
        _setDeployer(newDeployer);
    }

    /**
     * @notice Test function to directly call _setDeployer
     */
    function testSetDeployer(address newDeployer) external {
        _setDeployer(newDeployer);
    }

    /**
     * @notice Test function to update ITS address
     */
    function setITSAddress(address newITS) external {
        itsAddress = newITS;
    }
}