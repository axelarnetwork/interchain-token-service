// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20 {
    function mint(address to, uint256 amount) external;

    // TODO: need to understand what the common interface is for burning, burnFrom etc.
    function burn(address from, uint256 amount) external;
}
