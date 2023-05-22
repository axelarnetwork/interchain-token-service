// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenLinker } from './TokenLinker.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract TokenLinkerMintBurn is TokenLinker {
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenLinker(interchainTokenService_)
    {}

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20BurnableMintable.burnFrom.selector, from, amount));

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
