// SPDX-License-Identifier: MIT

// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.0;

import { TokenManagerLiquidityPool } from '../token-manager/TokenManagerLiquidityPool.sol';
import { Distributable } from '../utils/Distributable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { Operatable } from '../utils/Operatable.sol';
import { InterchainToken } from '../interchain-token/InterchainToken.sol';

error Invalid();

contract TestTokenManager is TokenManagerLiquidityPool {
    string public constant NAME = 'TestTokenManager';

    constructor(address interchainTokenService_) TokenManagerLiquidityPool(interchainTokenService_) {
        if (TOKEN_ADDRESS_SLOT != uint256(keccak256('token-address')) - 1) revert Invalid();
        if (LIQUIDITY_POOL_SLOT != uint256(keccak256('liquidity-pool-slot')) - 1) revert Invalid();
    }
}

contract TestDistributable is Distributable {
    string public constant NAME = 'TestDistributable';

    constructor() {}
}

contract TestFlowLimit is FlowLimit {
    string public constant NAME = 'TestFlowLimit';

    constructor() {
        if (FLOW_LIMIT_SLOT != uint256(keccak256('flow-limit')) - 1) revert Invalid();
    }
}

contract TestOperatable is Operatable {
    string public constant NAME = 'TestOperatable';

    constructor() {}
}

contract TestInterchainToken is InterchainToken {
    constructor() {
        if (INITIALIZED_SLOT != bytes32(uint256(keccak256('interchain-token-initialized')) - 1)) revert Invalid();
    }
}
