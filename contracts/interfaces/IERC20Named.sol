// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @title IERC20Named Interface
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Named is IERC20 {
    /**
     * @notice Getter for the name of the token.
     * @return string Name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Getter for the symbol of the token.
     * @return string The symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Getter for the decimals of the token.
     * @return uint8 The decimals of the token.
     */
    function decimals() external view returns (uint8);
}
