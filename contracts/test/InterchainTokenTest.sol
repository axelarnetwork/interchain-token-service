// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainToken } from '../interchain-token/InterchainToken.sol';
import { Distributable } from '../utils/Distributable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';

contract InterchainTokenTest is InterchainToken, Distributable, IERC20MintableBurnable {
    ITokenManager public tokenManager_;
    bool internal tokenManagerRequiresApproval_ = true;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address tokenManagerAddress) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _addDistributor(msg.sender);
        tokenManager_ = ITokenManager(tokenManagerAddress);
    }

    function tokenManager() public view override returns (ITokenManager) {
        return tokenManager_;
    }

    function _beforeInterchainTransfer(
        address sender,
        string calldata /*destinationChain*/,
        bytes calldata /*destinationAddress*/,
        uint256 amount,
        bytes calldata /*metadata*/
    ) internal override {
        if (!tokenManagerRequiresApproval_) return;
        address tokenManagerAddress = address(tokenManager_);
        uint256 allowance_ = allowance[sender][tokenManagerAddress];
        if (allowance_ != UINT256_MAX) {
            if (allowance_ > UINT256_MAX - amount) {
                allowance_ = UINT256_MAX - amount;
            }

            _approve(sender, tokenManagerAddress, allowance_ + amount);
        }
    }

    function setTokenManagerRequiresApproval(bool requiresApproval) public {
        tokenManagerRequiresApproval_ = requiresApproval;
    }

    function mint(address account, uint256 amount) external onlyRole(DISTRIBUTOR) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(DISTRIBUTOR) {
        _burn(account, amount);
    }

    function setTokenManager(ITokenManager tokenManagerAddress) external {
        tokenManager_ = tokenManagerAddress;
    }
}
