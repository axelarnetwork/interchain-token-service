// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { InterchainToken } from '../interchainToken/InterchainToken.sol';

contract InterchainTokenTest is InterchainToken {
    constructor(
        address interchainTokenServiceAddress_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address distributor_,
        uint256 supply_
    ) InterchainToken(interchainTokenServiceAddress_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _mint(distributor_, supply_);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, interchainTokenServiceAddress_)
        }
        interchainTokenService.registerSelfAsInterchainToken();
    }
}
