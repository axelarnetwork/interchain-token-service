// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDistributable {
    error NotDistributor();

    event DistributorChanged(address distributor);

    function distributor() external view returns (address distributor);

    function setDistributor(address distributor) external;
}
