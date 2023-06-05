// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManager } from '../TokenManager.sol';
import { IERC20BurnableMintable } from '../../interfaces/IERC20BurnableMintable.sol';

contract TokenManagerMintBurn is TokenManager {
    address public tokenAddress;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManager(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, tokenAddress) = abi.decode(params, (address, address));
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20BurnableMintable.burn.selector, from, amount));

        if (!success || token.code.length == 0) revert TakeTokenFailed();
        return amount;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, to, amount));

        if (!success || token.code.length == 0) revert GiveTokenFailed();
        return amount;
    }
}
