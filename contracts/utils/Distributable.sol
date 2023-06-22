// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IDistributable } from '../interfaces/IDistributable.sol';

/**
 * @title Distributable Contract
 * @author Foivos Antoulinakis
 * @dev A contract module which provides a basic access control mechanism, where
 * there is an account (a distributor) that can be granted exclusive access to
 * specific functions. This module is used through inheritance.
 */
contract Distributable is IDistributable {
    // uint256(keccak256('distributor')) - 1
    uint256 internal constant DISTRIBUTOR_SLOT = 0x71c5a35e45a25c49e8f747acd4bcb869814b3d104c492d2554f4c46e12371f56;

    /**
     * @dev Throws a NotDistributor custom eror if called by any account other than the distributor.
     */
    modifier onlyDistributor() {
        if (distributor() != msg.sender) revert NotDistributor();
        _;
    }

    /**
     * @notice Get the address of the distributor
     * @return distr of the distributor
     */
    function distributor() public view returns (address distr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            distr := sload(DISTRIBUTOR_SLOT)
        }
    }

    /**
     * @dev Internal function that stores the new distributor address in the correct storage slot
     * @param distributor_ The address of the new distributor
     */
    function _setDistributor(address distributor_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(DISTRIBUTOR_SLOT, distributor_)
        }
    }

    /**
     * @notice Change the distributor of the contract
     * @dev Can only be called by the current distributor
     * @param distr The address of the new distributor
     */
    function setDistributor(address distr) external onlyDistributor {
        _setDistributor(distr);
    }
}
