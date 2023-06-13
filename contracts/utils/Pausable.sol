// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IPausable } from '../interfaces/IPausable.sol';

contract Pausable is IPausable {
    // uint256(keccak256('paused'))-1
    uint256 internal constant ADMIN_SLOT = 0xee35723ac350a69d2a92d3703f17439cbaadf2f093a21ba5bf5f1a53eb2a14d8;

    modifier notPaused() {
        if (isPaused()) revert Paused();
        _;
    }

    function isPaused() public view returns (bool paused) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            paused := sload(ADMIN_SLOT)
        }
    }

    function _setPaused(bool paused) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(ADMIN_SLOT, paused)
        }
    }
}
