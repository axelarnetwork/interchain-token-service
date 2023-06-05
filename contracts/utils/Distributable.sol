// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IDistributable } from '../interfaces/IDistributable.sol';

contract Distributable is IDistributable {
    // uint256(keccak256('distributor'))-1
    uint256 internal constant DISTRIBUTOR_SLOT = 0x71c5a35e45a25c49e8f747acd4bcb869814b3d104c492d2554f4c46e12371f56;

    modifier onlyDistributor() {
        if(distributor() != msg.sender) revert NotDistributor();
        _;
    }

    function distributor() public view returns (address distr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            distr := sload(DISTRIBUTOR_SLOT)
        }
    }

    function _setDistributor(address distr) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(DISTRIBUTOR_SLOT, distr)
        }
    }

    function setDistributor(address distr) external onlyDistributor {
        _setDistributor(distr);
    }
}
