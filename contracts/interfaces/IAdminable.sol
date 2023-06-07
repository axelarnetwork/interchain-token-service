// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAdminable {
    error NotAdmin();

    function admin() external view returns (address admin_);

    function setAdmin(address admin_) external;
}
