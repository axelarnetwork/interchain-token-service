// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDistributable {
    error NotDistributor();

    event DistributorChanged(address distributor);

    /**
     * @notice Get the address of the distributor
     * @return distributor of the distributor
     */
    function distributor() external view returns (address distributor);

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distributor The address of the new distributor
     */
    function setDistributor(address distributor) external;
}
