// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { Ownable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';

contract InterchainTokenTest is InterchainToken, Ownable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        address owner = msg.sender;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, owner)
        }
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        uint256 _allowance = allowance[account][msg.sender];
        if (_allowance != type(uint256).max) {
            _approve(account, msg.sender, _allowance - amount);
        }
        _burn(account, amount);
    }
}
