// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Named is IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);
}
