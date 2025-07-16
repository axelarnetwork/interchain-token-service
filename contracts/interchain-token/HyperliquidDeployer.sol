// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title HyperliquidDeployer
 * @notice This contract allows setting a deployer address associated to an Interchain token.
 * The deployer address is stored in a storage slot calculated as keccak256(address) where
 * the address is the deployer address being stored. This provides a deterministic storage
 * location for each unique deployer address.
 * This is specifically for the linking of Interchain tokens between Hyperliquid EVM and Core
 * where the deployer address used to deploy a spot asset in HyperCore matches the address stored
 * in the calculated storage slot of the ERC20 token deployed in Hyperliquid EVM via create2 mechanism.
 */
abstract contract HyperliquidDeployer {
    // Hyperliquid Specific Storage Slot
    bytes32 private constant DEPLOYER_SLOT = keccak256('HyperCore deployer');

    /**
     * @notice Gets the deployer address stored in the deployer slot
     * @return deployerAddr The address of the deployer
     */
    function _deployer() internal view virtual returns (address deployerAddr) {
        bytes32 slot = DEPLOYER_SLOT;
        assembly {
            deployerAddr := sload(slot)
        }
    }

    /**
     * @notice Internal function to set the deployer address in the deployer slot
     * @param deployerAddr The address to store as deployer
     */
    function _setDeployer(address deployerAddr) internal {
        bytes32 slot = DEPLOYER_SLOT;
        assembly {
            sstore(slot, deployerAddr)
        }
    }
}
