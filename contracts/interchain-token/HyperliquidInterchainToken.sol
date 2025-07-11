// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from './InterchainToken.sol';
import { HyperliquidDeployer } from './HyperliquidDeployer.sol';
import { IHyperliquidDeployer } from '../interfaces/IHyperliquidDeployer.sol';

/**
 * @title HyperliquidInterchainToken
 * @notice This contract implements an interchain token with Hyperliquid-specific modifications.
 * @dev Inherits from HyperLiquidDeployer to use keccak256-based storage slots for deployer addresses,
 * then from InterchainToken for standard functionality.
 * This maintains the standard InterchainToken while providing Hyperliquid compatibility.
 */
contract HyperliquidInterchainToken is HyperliquidDeployer, InterchainToken, IHyperliquidDeployer {
    error NotService(address caller);

    /// bytes32(uint256(keccak256('hyperliquid-interchain-token-deployer')) - 1)
    bytes32 private constant CURRENT_DEPLOYER_SLOT = 0x8f802fa116fa5e7a7e0f94874e9214762d5a91faa240ab5140b3a79fbca28666;

    /**
     * @notice Modifier to restrict access to only the interchain token service
     */
    modifier onlyService() {
        if (msg.sender != interchainTokenService_) {
            revert NotService(msg.sender);
        }
        _;
    }

    /**
     * @notice Constructs the HyperliquidInterchainToken contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) InterchainToken(interchainTokenServiceAddress) {}

    /**
     * @notice Gets the current active deployer address
     * @return deployerAddr The address of the current deployer
     */
    function deployer() external view override returns (address deployerAddr) {
        bytes32 slot = CURRENT_DEPLOYER_SLOT;
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return address(uint160(uint256(value)));
    }

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external override onlyService {
        bytes32 slot = CURRENT_DEPLOYER_SLOT;
        assembly {
            sstore(slot, newDeployer)
        }
    }
}
