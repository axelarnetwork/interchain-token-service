// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManager } from '../token-manager/TokenManager.sol';

contract TestTokenManager is TokenManager {
    constructor(address service) TokenManager(service) {}

    function addOperator(address operator) external {
        _addOperator(operator);
    }
}
