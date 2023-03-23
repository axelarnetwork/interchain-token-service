// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Named is IERC20 {
    function interchainTransfer(
        string calldata destinationChain,
        string calldata recipient,
        uint256 amount,
        uint256 transferType, // on hold for now
        bytes calldata metadata
    ) external payable;

    // Send a token cross-chain from an account that has an approval to spend from `sender`'s balance
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        string calldata recipient,
        uint256 amount,
        uint256 transferType, // on hold for now
        bytes calldata metadata
    ) external payable;
}
