// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IProxy.sol';

/**
 * @title ITokenManagerProxy
 * @dev This interface is implemented by the token manager proxy contract.
 */
interface ITokenManagerProxy is IProxy {
    /**
     * @notice Returns implementation type of this token manager
     */
    function implementationType() external view returns (uint256);

    /**
     * @notice Returns token ID of the token manager.
     */
    function interchainTokenId() external view returns (bytes32);
}
