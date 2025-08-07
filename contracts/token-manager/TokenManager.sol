// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseTokenManager } from './BaseTokenManager.sol';

/**
 * @title TokenManager
 * @notice This contract is responsible for managing tokens, such as setting locking token balances, or setting flow limits, for interchain transfers.
 */
contract TokenManagerAxelar is BaseTokenManager {
    /**
     * @notice Constructs the TokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service.
     */
    constructor(address interchainTokenService_) BaseTokenManager(interchainTokenService_) {}
} 
