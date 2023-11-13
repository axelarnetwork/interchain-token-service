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
    string public placeholder;

    constructor(address interchainTokenService_) TokenManagerLiquidityPool(interchainTokenService_) {
        if (LIQUIDITY_POOL_SLOT != uint256(keccak256('liquidity-pool-slot')) - 1) revert Invalid();
    }
}

contract TestFlowLimit is FlowLimit {
    string public placeholder;

    constructor() {
        if (FLOW_LIMIT_SLOT != uint256(keccak256('flow-limit')) - 1) revert Invalid();
    }
}

contract TestInterchainToken is InterchainToken {
    string public placeholder;

    constructor() {
        if (INITIALIZED_SLOT != bytes32(uint256(keccak256('interchain-token-initialized')) - 1)) revert Invalid();
    }
}
