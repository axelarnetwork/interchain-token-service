// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HyperliquidInterchainToken } from '../interchain-token/HyperliquidInterchainToken.sol';

contract TestHyperliquidInterchainToken is HyperliquidInterchainToken {
    bool internal tokenManagerRequiresApproval_ = true;

    error AllowanceExceeded();

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address service_,
        bytes32 tokenId_
    ) HyperliquidInterchainToken(service_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        tokenId = tokenId_;
        _addMinter(msg.sender);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance[account][msg.sender];
        if (currentAllowance < amount) revert AllowanceExceeded();
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    function setTokenId(bytes32 tokenId_) external {
        tokenId = tokenId_;
    }
}
