// SPDX-License-Identifier: MIT

// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.0;

import { TokenManagerLiquidityPool } from '../token-manager/TokenManagerLiquidityPool.sol';
import { InterchainToken } from '../interchain-token/InterchainToken.sol';

error Invalid();

contract TestTokenManagerLiquidityPool is TokenManagerLiquidityPool {
    string public placeholder;

    constructor(address interchainTokenService_) TokenManagerLiquidityPool(interchainTokenService_) {
        if (LIQUIDITY_POOL_SLOT != bytes32(uint256(keccak256('liquidity-pool')) - 1)) revert Invalid();
    }
}

contract TestInterchainToken is InterchainToken {
    string public placeholder;

    constructor() {
        if (INITIALIZED_SLOT != bytes32(uint256(keccak256('interchain-token-initialized')) - 1)) revert Invalid();
    }
}
