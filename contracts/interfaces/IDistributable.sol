// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IDistributable {
    error NotDistributor();

    function distributor() external view returns (address distributor);

    function setDistributor(address distributor) external;
}
