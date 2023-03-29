// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ERC20 } from './ERC20.sol';
import { Ownable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract ERC20BurnableMintable is ERC20, Ownable, IERC20BurnableMintable {
    string public name;
    string public symbol;
    uint8 public decimals;

    function setup(string memory name_, string memory symbol_, uint8 decimals_, address owner) external {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
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
