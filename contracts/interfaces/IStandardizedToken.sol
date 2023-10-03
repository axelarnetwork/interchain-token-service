// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from './IImplementation.sol';
import { IInterchainToken } from './IInterchainToken.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

/**
 * @title StandardizedToken
 * @notice This contract implements a standardized token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
interface IStandardizedToken is IImplementation, IInterchainToken, IDistributable, IERC20MintableBurnable, IERC20 {
    error TokenManagerAddressZero();
    error TokenNameEmpty();
    /**
     * @notice Returns the contract id, which a proxy can check to ensure no false implementation was used.
     */
    function contractId() external view returns (bytes32);
}
