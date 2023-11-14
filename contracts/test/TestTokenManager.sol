// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManagerLockUnlock } from '../token-manager/TokenManagerLockUnlock.sol';

contract TestTokenManager is TokenManagerLockUnlock {
    constructor(address service) TokenManagerLockUnlock(service) {}

    function addOperator(address operator) external {
        _addOperator(operator);
    }
}
