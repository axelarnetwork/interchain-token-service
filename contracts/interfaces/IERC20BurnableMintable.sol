// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IDistributable } from './IDistributable.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IDistributable, IERC20Named {
    error NotProxy();

    function setup(bytes calldata setupParams) external;

    function mint(address to, uint256 amount) external;

    // TODO: need to understand what the common interface is for burning, burnFrom etc.
    function burn(address from, uint256 amount) external;
}
