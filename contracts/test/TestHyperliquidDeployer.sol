// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HyperliquidDeployer } from '../interchain-token/HyperliquidDeployer.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title TestHyperliquidDeployer
 * @notice Concrete implementation of HyperliquidDeployer for testing
 * @dev This contract is used to test the HyperLiquid ITS contract's updateTokenDeployer function
 */
contract TestHyperliquidDeployer is HyperliquidInterchainToken {
    error NotService(address caller);

    address public itsAddress;
    address public initialDeployer;

    /**
     * @notice Modifier to restrict access to only the interchain token service
     */
    modifier onlyService() {
        if (msg.sender != itsAddress) {
            revert NotService(msg.sender);
        }
        _;
    }

    constructor(address _itsAddress, address _initialDeployer) {
        itsAddress = _itsAddress;
        initialDeployer = _initialDeployer;
        _setDeployer(_initialDeployer);
    }

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return The address of the deployer
     */
    function deployer() external view override returns (address) {
        return _deployer();
    }

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override onlyService {
        _setDeployer(newDeployer);
    }

    /**
     * @notice Test function to directly call _setDeployer (for setup purposes)
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
