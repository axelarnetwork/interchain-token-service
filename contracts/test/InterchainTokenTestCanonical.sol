// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { Distributable } from '../utils/Distributable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';

contract InterchainTokenTestCanonical is InterchainToken, Distributable {
    ITokenManager internal immutable tokenManager;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, IInterchainTokenService service) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _setDistributor(msg.sender);
        bytes32 tokenId = service.getCanonicalTokenId(address(this));
        tokenManager = ITokenManager(service.getTokenManagerAddress(tokenId));
    }

    function getTokenManager() public override view returns (ITokenManager) {
        return tokenManager;
    }

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
