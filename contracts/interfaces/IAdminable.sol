// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAdminable {
    error NotAdmin();

    event AdminChanged(address admin);

    function admin() external view returns (address admin_);

    function setAdmin(address admin_) external;
}
