// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Ownable.sol';
import { Pausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Pausable.sol';
import { InterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/InterchainAddressTracker.sol';


import { Operator } from './utils/Operator.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IInterchainTokenServiceProxy } from './interfaces/IInterchainTokenServiceProxy.sol';
import { IInterchainTokenServiceImplementation } from './interfaces/IInterchainTokenServiceImplementation.sol';

contract InterchainTokenServiceImplementation is 
    Operator,
    Ownable,
    Pausable,
    InterchainAddressTracker
{   
    /**
     * @dev Since this is an implementation it does not need to have an owner in its storage.
     */
    constructor() Ownable(address(this)) {}

    /**
     * @notice Getter function for the flow limit of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowLimit_ The flow limit.
     */
    function flowLimit(bytes32 tokenId) external view returns (uint256 flowLimit_) {
        ITokenManager tokenManager_ = ITokenManager(IInterchainTokenServiceProxy(address(this)).validTokenManagerAddress(tokenId));
        flowLimit_ = tokenManager_.flowLimit();
    }

    /**
     * @notice Getter function for the flow out amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowOutAmount_ The flow out amount.
     */
    function flowOutAmount(bytes32 tokenId) external view returns (uint256 flowOutAmount_) {
        ITokenManager tokenManager_ = ITokenManager(IInterchainTokenServiceProxy(address(this)).validTokenManagerAddress(tokenId));
        flowOutAmount_ = tokenManager_.flowOutAmount();
    }

    /**
     * @notice Getter function for the flow in amount of an existing TokenManager with a given tokenId.
     * @param tokenId The tokenId of the TokenManager.
     * @return flowInAmount_ The flow in amount.
     */
    function flowInAmount(bytes32 tokenId) external view returns (uint256 flowInAmount_) {
        ITokenManager tokenManager_ = ITokenManager(IInterchainTokenServiceProxy(address(this)).validTokenManagerAddress(tokenId));
        flowInAmount_ = tokenManager_.flowInAmount();
    }

    /*************\
    OWNER FUNCTIONS
    \*************/

    /**
     * @notice Used to set a flow limit for a token manager that has the service as its operator.
     * @param tokenIds An array of the tokenIds of the tokenManagers to set the flow limits of.
     * @param flowLimits The flowLimits to set.
     */
    function setFlowLimits(bytes32[] calldata tokenIds, uint256[] calldata flowLimits) external onlyRole(uint8(Roles.OPERATOR)) {
        uint256 length = tokenIds.length;
        if (length != flowLimits.length) revert LengthMismatch();

        for (uint256 i; i < length; ++i) {
            ITokenManager tokenManager_ = ITokenManager(IInterchainTokenServiceProxy(address(this)).validTokenManagerAddress(tokenIds[i]));
            // slither-disable-next-line calls-loop
            tokenManager_.setFlowLimit(flowLimits[i]);
        }
    }

    /**
     * @notice Used to set a trusted address for a chain.
     * @param chain The chain to set the trusted address of.
     * @param address_ The address to set as trusted.
     */
    function setTrustedAddress(string memory chain, string memory address_) external onlyOwner {
        _setTrustedAddress(chain, address_);
    }

    /**
     * @notice Used to remove a trusted address for a chain.
     * @param chain The chain to set the trusted address of.
     */
    function removeTrustedAddress(string memory chain) external onlyOwner {
        _removeTrustedAddress(chain);
    }

    /**
     * @notice Allows the owner to pause/unpause the token service.
     * @param paused Boolean value representing whether to pause or unpause.
     */
    function setPauseStatus(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }
}