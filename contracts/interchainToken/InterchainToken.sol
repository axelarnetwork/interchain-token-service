// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { ERC20 } from '../utils/ERC20.sol';

contract InterchainToken is IInterchainToken, ERC20 {
    function interchainTransfer(
        string calldata destinationChain,
        string calldata recipient,
        uint256 amount,
        uint256 transferType, // on hold for now
        bytes calldata metadata
    ) external payable // solhint-disable-next-line no-empty-blocks
    {
        //TODO: add implementation
    }

    // Send a token cross-chain from an account that has an approval to spend from `sender`'s balance
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        string calldata recipient,
        uint256 amount,
        uint256 transferType, // on hold for now
        bytes calldata metadata
    ) external payable // solhint-disable-next-line no-empty-blocks
    {
        //TODO: add implementation
    }
}
