// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20BurnableMintable } from './IERC20BurnableMintable.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IInterchainToken is IERC20BurnableMintable {
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    // Send a token cross-chain from an account that has an approval to spend from `sender`'s balance
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}
