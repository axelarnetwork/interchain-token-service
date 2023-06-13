// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { SafeTokenTransferFrom, SafeTokenTransfer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';


contract TokenManagerLockUnlock is TokenManagerAddressStorage {
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManagerAddressStorage(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function requiresApproval() external pure returns (bool) {
        return true;
    }

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, address tokenAddress) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress);
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = token.balanceOf(address(this));

        SafeTokenTransferFrom.safeTransferFrom(token, from, address(this), amount);

        // Note: This allows support for fee-on-transfer tokens
        return IERC20(token).balanceOf(address(this)) - balance;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = IERC20(token).balanceOf(to);

        SafeTokenTransfer.safeTransfer(token, to, amount);

        return IERC20(token).balanceOf(to) - balance;
    }
}
