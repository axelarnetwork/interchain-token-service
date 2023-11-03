// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title InterchainTokenFactoryProxy
 * @dev Proxy contract for interchain token service contracts. Inherits from the Proxy contract.
 */
contract TokenFactoryProxy is Proxy {
    bytes32 private constant CONTRACT_ID = keccak256('token-factory');

    /**
     * @dev Constructs the InterchainTokenServiceProxy contract.
     * @param implementationAddress Address of the interchain token service implementation
     * @param owner Address of the owner of the proxy
     */
    constructor(address implementationAddress, address owner) Proxy(implementationAddress, owner, '') {}

    /**
     * @dev Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract.
     * @return bytes32 identifier for this contract
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
