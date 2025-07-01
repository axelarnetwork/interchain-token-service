// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HyperliquidInterchainToken } from '../interchain-token/HyperliquidInterchainToken.sol';

contract TestHyperliquidInterchainToken is HyperliquidInterchainToken {
    bool internal tokenManagerRequiresApproval_ = true;
    address public testITSAddress;
    address public initialDeployer;

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
        testITSAddress = service_;
        initialDeployer = address(0);
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

    /**
     * @notice Test function to directly call _setDeployer (for setup purposes)
     */
    function setDeployer(address newDeployer) external {
        _setDeployer(newDeployer);
    }

    /**
     * @notice Test function to update ITS address
     */
    function setITSAddress(address newITS) external {
        testITSAddress = newITS;
    }
}
