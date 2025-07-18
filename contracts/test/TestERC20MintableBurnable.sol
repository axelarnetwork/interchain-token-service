// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from '../interchain-token/ERC20.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';
import { Minter } from '../utils/Minter.sol';

/**
 * @title TestERC20MintableBurnable
 * @notice A simple ERC20 token implementation with minting and burning capabilities
 * @dev Extends the base ERC20 contract and implements named token interface
 */
contract TestERC20MintableBurnable is ERC20, IERC20Named, IERC20MintableBurnable, Minter {
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    /**
     * @notice Constructor to initialize the token with name, symbol, and decimals
     * @param tokenName The name of the token
     * @param tokenSymbol The symbol of the token
     * @param tokenDecimals The number of decimals for the token
     */
    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;

        // Add the deployer as the initial minter
        _addMinter(msg.sender);
    }

    /**
     * @notice Function to mint new tokens
     * @dev Can only be called by addresses with minter role
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external override onlyRole(uint8(Roles.MINTER)) {
        _mint(to, amount);
    }

    /**
     * @notice Function to burn tokens
     * @dev Can only be called by addresses with minter role
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external override onlyRole(uint8(Roles.MINTER)) {
        _burn(from, amount);
    }
}
