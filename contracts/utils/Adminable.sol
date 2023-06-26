// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IAdminable } from '../interfaces/IAdminable.sol';

/**
 * @title Adminable Contract
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Adminable is IAdminable {
    // uint256(keccak256('admin')) - 1
    uint256 internal constant ADMIN_SLOT = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d7;

    /**
     * @dev Throws a NotAdmin custom error if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        if (admin() != msg.sender) revert NotAdmin();
        _;
    }

    /**
     * @notice Get the address of the admin
     * @return distr of the admin
     */
    function admin() public view returns (address distr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            distr := sload(ADMIN_SLOT)
        }
    }

    /**
     * @dev Internal function that stores the new admin address in the admin storage slot
     * @param admin_ The address of the new admin
     */
    function _setAdmin(address admin_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(ADMIN_SLOT, admin_)
        }
        emit AdminChanged(admin_);
    }

    /**
     * @notice Change the admin of the contract
     * @dev Can only be called by the current admin
     * @param admin_ The address of the new admin
     */
    function setAdmin(address admin_) external onlyAdmin {
        _setAdmin(admin_);
    }
}
