// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';

import { IInterchainTokenBase } from './IInterchainTokenBase.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { ITokenManager } from './ITokenManager.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @title IInterchainToken
 */
interface IInterchainToken is IInterchainTokenBase, IDistributable, IERC20MintableBurnable, IERC20Named, IImplementation {
    error TokenManagerAddressZero();
    error TokenNameEmpty();

    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager_ the TokenManager called to facilitate cross chain transfers.
     */
    function tokenManager() external view returns (ITokenManager tokenManager_);
}
