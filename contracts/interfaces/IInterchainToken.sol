// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';

import { IInterchainTokenStandard } from './IInterchainTokenStandard.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @title IInterchainToken
 */
interface IInterchainToken is IInterchainTokenStandard, IDistributable, IERC20MintableBurnable, IERC20Named, IImplementation {
    error TokenManagerAddressZero();
    error TokenNameEmpty();

    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager_ the TokenManager called to facilitate cross chain transfers.
     */
    function tokenManager() external view returns (address tokenManager_);
}
