// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TestFeeOnTransferToken } from './TestFeeOnTransferToken.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';

contract TestFeeOnTransferTokenInvalid is TestFeeOnTransferToken {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address service_,
        bytes32 tokenId_
    ) TestFeeOnTransferToken(name_, symbol_, decimals_, service_, tokenId_) {}

    // reeentrant call
    function _transfer(address, address, uint256 amount) internal override {
        IInterchainTokenService(msg.sender).interchainTransfer(interchainTokenId(), '', new bytes(0), amount, new bytes(0));
    }
}
