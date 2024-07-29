// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAddressTracker } from './IAddressTracker.sol';

interface IInterchainTokenServiceImplementation is
    IAddressTracker
{
    /**
     * @notice Sets the flow limits for multiple tokens.
     * @param tokenIds An array of tokenIds.
     * @param flowLimits An array of flow limits corresponding to the tokenIds.
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external;

    /**
     * @notice Returns the flow limit for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowLimit_ The flow limit for the token.
     */
    function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_);

    /**
     * @notice Returns the total amount of outgoing flow for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowOutAmount_ The total amount of outgoing flow for the token.
     */
    function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_);

    /**
     * @notice Returns the total amount of incoming flow for a specific token.
     * @param tokenId The tokenId of the token.
     * @return flowInAmount_ The total amount of incoming flow for the token.
     */
    function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_);

    /**
     * @notice Allows the owner to pause/unpause the token service.
     * @param paused whether to pause or unpause.
     */
    function setPauseStatus(bool paused) external;
}