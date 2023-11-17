// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title InterchainTokenFactoryProxy
 * @notice Proxy contract for interchain token factory contracts.
 * @dev Inherits from the Proxy contract.
 */
contract InterchainTokenFactoryProxy is Proxy {
    bytes32 public constant CONTRACT_ID = keccak256('interchain-token-factory');

    /**
     * @dev Constructs the InterchainTokenFactoryProxy contract.
     * @param implementationAddress Address of the interchain token factory implementation.
     * @param owner Address of the owner of the proxy.
     */
    constructor(address implementationAddress, address owner) Proxy(implementationAddress, owner, '') {}

    /**
     * @notice Returns a unique identifier for this contract.
     * @dev Override for the `contractId` function in FinalProxy.
     * @return bytes32 Identifier for this contract.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
