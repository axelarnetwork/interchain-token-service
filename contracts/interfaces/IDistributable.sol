// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IDistributable {
    error NotDistributor();

    function distributor() external view returns (address distr);

    function setDistributor(address distributor) external;
}
