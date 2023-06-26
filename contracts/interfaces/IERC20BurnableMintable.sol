// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20 {
    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    // TODO: need to understand what the common interface is for burning, burnFrom etc.
    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;
}
