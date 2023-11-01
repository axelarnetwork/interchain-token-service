// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IContractIdentifier } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IContractIdentifier.sol';

import { IImplementation } from './IImplementation.sol';
import { IInterchainToken } from './IInterchainToken.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';

/**
 * @title IStandardizedToken Interface
 * @notice This interface implements a standardized token which extends InterchainToken functionality.
 */
interface IStandardizedToken is IImplementation, IInterchainToken, IDistributable, IERC20MintableBurnable, IERC20, IContractIdentifier {
    error TokenManagerAddressZero();
    error TokenNameEmpty();
}
