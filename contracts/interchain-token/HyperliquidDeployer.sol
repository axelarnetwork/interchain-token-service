// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title HyperliquidDeployer
 * @notice This contract allows setting a deployer address associated to an Interchain token.
 * The deployer address is stored in a storage slot calculated as keccak256('HyperCore deployer') where
 * This provides a deterministic storage location retrieving the deployer address.
 * This is specifically for the linking of Interchain tokens between Hyperliquid EVM and Core
 * where the deployer address used to deploy a spot asset in HyperCore matches the address stored
 * in the calculated storage slot of the ERC20 token deployed in Hyperliquid EVM via create2 mechanism.
 */
abstract contract HyperliquidDeployer {
    /// @dev Hyperliquid Deployer Storage Slot: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm/hypercore-less-than-greater-than-hyperevm-transfers#linking-core-and-evm-spot-assets
    bytes32 private constant DEPLOYER_SLOT = keccak256('HyperCore deployer');

    /**
     * @notice Gets the deployer address stored in the deployer slot
     * @return deployer The address of the deployer
     */
    function _deployer() internal view virtual returns (address deployer) {
        bytes32 slot = DEPLOYER_SLOT;
        assembly {
            deployer := sload(slot)
        }
    }

    /**
     * @notice Internal function to set the deployer address in the deployer slot
     * @param deployer The address to store as deployer
     */
    function _setDeployer(address deployer) internal {
        bytes32 slot = DEPLOYER_SLOT;
        assembly {
            sstore(slot, deployer)
        }
    }
}
