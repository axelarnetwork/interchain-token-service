// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { Distributable } from '../utils/Distributable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';

contract InterchainTokenTest is InterchainToken, Distributable {
    ITokenManager internal immutable tokenManager;

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

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}