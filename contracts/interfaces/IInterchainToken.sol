// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenStandard } from './IInterchainTokenStandard.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @title IInterchainToken
 */
interface IInterchainToken is IInterchainTokenStandard, IDistributable, IERC20MintableBurnable, IERC20Named {
    error TokenManagerAddressZero();
    error TokenNameEmpty();
    error AlreadyInitialized();

    /**
     * @notice Getter for the tokenManager used for this token.
     * @dev Needs to be overwitten.
     * @return tokenManager_ the TokenManager called to facilitate cross chain transfers.
     */
    function tokenManager() external view returns (address tokenManager_);

    /**
     * @notice Setup function to initialize contract parameters
     * @param tokenManagerAddress The address of the token manager of this token
     * @param distributor The address of the token distributor
     * @param tokenName The name of the token
     * @param tokenSymbol The symbopl of the token
     * @param tokenDecimals The decimals of the token
     */
    function init(
        address tokenManagerAddress,
        address distributor,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external;
}
