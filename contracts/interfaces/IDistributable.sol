// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistributable {
    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor_ The address of the new distributor
     */
    function transferDistributorship(address distributor_) external;

    /**
     * @notice Proposed a change of the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor_ The address of the new distributor
     */
    function proposeDistributorship(address distributor_) external;

    /**
     * @notice Accept a change of the distributor of the contract
     * @dev Can only be called by the proposed distributor
     */
    function acceptDistributorship(address fromDistributor) external;
}
