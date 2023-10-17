// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManagerLiquidityPool } from '../token-manager/implementations/TokenManagerLiquidityPool.sol';
import { Distributable } from '../utils/Distributable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { NoReEntrancy } from '../utils/NoReEntrancy.sol';
import { Operatable } from '../utils/Operatable.sol';
import { Pausable } from '../utils/Pausable.sol';

contract TestTokenManager is TokenManagerLiquidityPool {
    string public constant NAME = 'TestTokenManager';

    constructor(address interchainTokenService_) TokenManagerLiquidityPool(interchainTokenService_) {
        require(TOKEN_ADDRESS_SLOT == uint256(keccak256('token-address')) - 1, 'invalid constant');
        require(LIQUIDITY_POOL_SLOT == uint256(keccak256('liquidity-pool-slot')) - 1, 'invalid constant');
    }
}

contract TestDistributable is Distributable {
    string public constant NAME = 'TestDistributable';

    constructor() {
    }
}

contract TestFlowLimit is FlowLimit {
    string public constant NAME = 'TestFlowLimit';

    constructor() {
        require(FLOW_LIMIT_SLOT == uint256(keccak256('flow-limit')) - 1, 'invalid constant');
    }
}

contract TestNoReEntrancy is NoReEntrancy {
    string public constant NAME = 'TestNoReEntrancy';

    constructor() {
        require(ENTERED_SLOT == uint256(keccak256('entered')) - 1, 'invalid constant');
    }
}

contract TestOperatable is Operatable {
    string public constant NAME = 'TestOperatable';

    constructor() {
    }
}

contract TestPausable is Pausable {
    string public constant NAME = 'TestPausable';

    constructor() {
        require(PAUSE_SLOT == uint256(keccak256('paused')) - 1, 'invalid constant');
    }
}
