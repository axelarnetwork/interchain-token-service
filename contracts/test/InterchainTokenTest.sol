// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { InterchainToken } from '../interchain-token/InterchainToken.sol';
import { Distributable } from '../utils/Distributable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract InterchainTokenTest is InterchainToken, Distributable, IERC20BurnableMintable {
    ITokenManager internal tokenManager;
    bool internal tokenManagerRequiresApproval_ = true;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address tokenManager_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _setDistributor(msg.sender);
        tokenManager = ITokenManager(tokenManager_);
    }

    function getTokenManager() public view override returns (ITokenManager) {
        return tokenManager;
    }

    function tokenManagerRequiresApproval() public view override returns (bool) {
        return tokenManagerRequiresApproval_;
    }

    function setTokenManagerRequiresApproval(bool requiresApproval) public {
        tokenManagerRequiresApproval_ = requiresApproval;
    }

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }

    function setTokenManager(ITokenManager tokenManager_) external {
        tokenManager = tokenManager_;
    }
}
