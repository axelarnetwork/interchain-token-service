// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManager } from '../TokenManager.sol';
import { InterchainToken } from '../../interchainToken/InterchainToken.sol';

contract TokenManagerCanonical is TokenManager, InterchainToken {
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManager(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function tokenAddress() external view returns (address) {
        return address(this);
    }

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, name, symbol, decimals) = abi.decode(params, (address, string, string, uint8));
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
