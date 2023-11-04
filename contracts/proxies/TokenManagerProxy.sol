// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IProxy.sol';
import { BaseProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/BaseProxy.sol';

import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { ITokenManagerImplementation } from '../interfaces/ITokenManagerImplementation.sol';

/**
 * @title TokenManagerProxy
 * @notice This contract is a proxy for token manager contracts.
 * @dev It implements ITokenManagerProxy.
 */
contract TokenManagerProxy is BaseProxy, ITokenManagerProxy {
    bytes32 private constant CONTRACT_ID = keccak256('token-manager');

    address public immutable interchainTokenService;
    uint256 public immutable implementationType;
    bytes32 public immutable interchainTokenId;

    /**
     * @dev Constructs the TokenManagerProxy contract.
     * @param interchainTokenService_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @param tokenId The identifier for the token
     * @param params The initialization parameters for the token manager contract
     */
    constructor(address interchainTokenService_, uint256 implementationType_, bytes32 tokenId, bytes memory params) {
        interchainTokenService = interchainTokenService_;
        implementationType = implementationType_;
        interchainTokenId = tokenId;
        address implementation_ = _tokenManagerImplementation(interchainTokenService_, implementationType_);

        (bool success, ) = implementation_.delegatecall(abi.encodeWithSelector(IProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @dev Returns the contract ID.
     * @return bytes32 The contract ID
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @dev Returns the address of the current implementation.
     * @return implementation_ The address of the current implementation
     */
    function implementation() public view override(BaseProxy, IProxy) returns (address implementation_) {
        implementation_ = _tokenManagerImplementation(interchainTokenService, implementationType);
    }

    /**
     * @dev Returns the implementation address from the interchain token service for the provided type.
     * @param interchainTokenService_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @return implementation_ The address of the implementation
     */
    function _tokenManagerImplementation(
        address interchainTokenService_,
        uint256 implementationType_
    ) internal view returns (address implementation_) {
        implementation_ = ITokenManagerImplementation(interchainTokenService_).tokenManagerImplementation(implementationType_);
    }
}
