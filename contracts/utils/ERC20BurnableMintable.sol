// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ERC20 } from './ERC20.sol';
import { Distributable } from './Distributable.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract ERC20BurnableMintable is ERC20, Distributable, IERC20BurnableMintable {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public immutable implementationAddress;

    constructor() {
        implementationAddress = address(this);
    }

    modifier onlyProxy() {
        // Why are we using proxy pattern here?
        // The following will revert due to the above
        // Prevent setup from being called on the implementation
        if (address(this) == implementationAddress) revert NotProxy();

        _;
    }

    function setup(bytes calldata setupParams) external onlyProxy {
        (string memory name_, string memory symbol_, uint8 decimals_, address distr) = abi.decode(
            setupParams,
            (string, string, uint8, address)
        );
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _setDistributor(distr);
    }

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
