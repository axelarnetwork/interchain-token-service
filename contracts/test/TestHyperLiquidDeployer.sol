// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HyperLiquidDeployer } from '../interchain-token/HyperLiquidDeployer.sol';

/**
 * @title TestHyperLiquidDeployer
 * @notice Concrete implementation of HyperLiquidDeployer for testing
 */
contract TestHyperLiquidDeployer is HyperLiquidDeployer {
    address public itsAddress;
    address public initialDeployer;

    constructor(address _itsAddress, address _initialDeployer) {
        itsAddress = _itsAddress;
        initialDeployer = _initialDeployer;
        _setDeployer(_initialDeployer);
    }

    /**
     * @notice Implementation of abstract function to return ITS address
     */
    function _getInterchainTokenService() internal view override returns (address) {
        return itsAddress;
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
