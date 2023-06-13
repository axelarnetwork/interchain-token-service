// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAdminable } from '../interfaces/IAdminable.sol';

contract Adminable is IAdminable {
    // uint256(keccak256('admin')) - 1
    uint256 internal constant ADMIN_SLOT = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d7;

    modifier onlyAdmin() {
        if (admin() != msg.sender) revert NotAdmin();
        _;
    }

    function admin() public view returns (address distr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            distr := sload(ADMIN_SLOT)
        }
    }

    function _setAdmin(address admin_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(ADMIN_SLOT, admin_)
        }
    }

    function setAdmin(address admin_) external onlyAdmin {
        _setAdmin(admin_);
    }
}
