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
    /**
     * @notice Gets the deployer address stored in the calculated storage slot
     * @param deployerAddr The address to get the deployer for
     * @return The address of the deployer (returns address(0) if not set)
     */
    function _deployer(address deployerAddr) internal view virtual returns (address) {
        bytes32 slot = keccak256(abi.encodePacked(deployerAddr));
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return address(uint160(uint256(value)));
    }

    /**
     * @notice Internal function to set the deployer address in the calculated storage slot
     * @param deployerAddr The address to store as deployer
     */
    function _setDeployer(address deployerAddr) internal {
        bytes32 slot = keccak256(abi.encodePacked(deployerAddr));
        assembly {
            sstore(slot, deployerAddr)
        }
    }
}
