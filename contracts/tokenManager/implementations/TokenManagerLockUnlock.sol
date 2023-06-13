// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

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
        address token = tokenAddress();
        uint256 balance = IERC20(token).balanceOf(address(this));

        // Can we lock the tokens on the ITS instead? It'll be simpler for tracking/monitoring
        // Use SafeERC20 interface from gmp sdk
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert TakeTokenFailed();

        // Note: This allows support for fee-on-transfer tokens
        return IERC20(token).balanceOf(address(this)) - balance;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress();
        uint256 balance = IERC20(token).balanceOf(to);
        // Use SafeERC20 interface from gmp sdk
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert GiveTokenFailed();
        return IERC20(token).balanceOf(to) - balance;
    }
}
