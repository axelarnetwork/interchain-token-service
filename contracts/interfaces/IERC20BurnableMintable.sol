// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20Named } from './IERC20Named.sol';
import { IOwnable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IOwnable.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintable is IERC20Named, IOwnable {
    error NotProxy();

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setup(bytes calldata setupParams) external;

    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}
