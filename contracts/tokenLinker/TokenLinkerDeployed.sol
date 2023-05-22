// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenLinker } from './TokenLinker.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';
import { ERC20 } from '../utils/ERC20.sol';

contract TokenLinkerMintBurn is TokenLinker, ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenLinker(interchainTokenService_)
    {}

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        _burn(from, amount);
        return amount;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        _mint(to, amount);
        return amount;
    }

    function _setup(bytes calldata params) internal override {
        (, , string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) = abi.decode(
            params,
            (address, address, string, string, uint8)
        );
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }
}
