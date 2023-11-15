// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TestFeeOnTransferToken } from './TestFeeOnTransferToken.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';

contract TestFeeOnTransferTokenInvalid is TestFeeOnTransferToken {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address tokenManagerAddress
    ) TestFeeOnTransferToken(name_, symbol_, decimals_, tokenManagerAddress) {}

    // reeentrant call
    function _transfer(address, address, uint256 amount) internal override {
        ITokenManager(msg.sender).interchainTransfer('', new bytes(0), amount, new bytes(0));
    }
}
