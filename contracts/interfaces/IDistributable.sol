// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IRolesBase } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IRolesBase.sol';

interface IDistributable is IRolesBase {
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

    /**
     * @notice Query if an address is a distributor
     * @param addr the address to query for
     */
    function isDistributor(address addr) external view returns (bool);
}
