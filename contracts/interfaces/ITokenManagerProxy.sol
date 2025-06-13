// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IProxy.sol';

/**
 * @title ITokenManagerProxy Interface
 * @notice This interface is for a proxy for token manager contracts.
 */
interface ITokenManagerProxy is IProxy {
    error ZeroAddress();
    error NotSupported(bytes data);
    error InterchainTokenDeploymentFailed(bytes error);

    /**
     * @notice Returns implementation type of this token manager.
     * @return uint256 The implementation type of this token manager.
     */
    function implementationType() external view returns (uint256);

    /**
     * @notice Returns the interchain token ID of the token manager.
     * @return bytes32 The interchain token ID of the token manager.
     */
    function interchainTokenId() external view returns (bytes32);

    /**
     * @notice Returns token address that this token manager manages.
     * @return address The token address.
     */
    function tokenAddress() external view returns (address);

    /**
     * @notice Returns implementation type and token address.
     * @return uint256 The implementation type.
     * @return address The token address.
     */
    function getImplementationTypeAndTokenAddress() external view returns (uint256, address);

    /**
     * @notice Returns whether the token is an HTS token.
     * @return bool True if the token is an HTS token, false otherwise.
     */
    function isHtsToken() external view returns (bool);
}
