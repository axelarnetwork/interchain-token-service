// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManager } from '../TokenManager.sol';
import { InterchainToken } from '../../interchainToken/InterchainToken.sol';
import { AddressBytesUtils } from '../../libraries/AddressBytesUtils.sol';
import { ITokenManager } from '../../interfaces/ITokenManager.sol';

contract TokenManagerCanonical is TokenManager, InterchainToken {
    using AddressBytesUtils for bytes;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManager(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function tokenAddress() public override view returns (address) {
        return address(this);
    }

    function getTokenManager() public override view returns (ITokenManager tokenManager) {
        return ITokenManager(this);
    }

    function requiresApproval() external pure returns (bool) {
        return false;
    }

    function _setup(bytes calldata params) internal override {
        uint256 mintAmount;
        bytes memory admin;
        //the first argument is reserved for the admin.
        (admin, name, symbol, decimals, mintAmount) = abi.decode(params, (bytes, string, string, uint8, uint256));
        if (mintAmount > 0) {
            // Not sure why initial mint for an arbitrary admin address is needed natively.
            // Better to keep it simpler I think and it can be done at a higher level if needed.
            _mint(admin.toAddress(), mintAmount);
        }
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        _burn(from, amount);
        return amount;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        _mint(to, amount);
        return amount;
    }
}
