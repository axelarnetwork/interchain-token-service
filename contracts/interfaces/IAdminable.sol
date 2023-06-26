// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAdminable {
    error NotAdmin();

    event AdminChanged(address admin);

    /**
     * @notice Get the address of the admin
     * @return admin_ of the admin
     */
    function admin() external view returns (address admin_);

    /**
     * @notice Change the admin of the contract
     * @dev Can only be called by the current admin
     * @param admin_ The address of the new admin
     */
    function setAdmin(address admin_) external;
}
