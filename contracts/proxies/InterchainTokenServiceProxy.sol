// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FinalProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FinalProxy.sol';

/**
 * @title InterchainTokenServiceProxy
 * @dev Proxy contract for interchain token service contracts. Inherits from the FinalProxy contract.
 */
contract InterchainTokenServiceProxy is FinalProxy {
    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');

    /**
     * @dev Constructs the InterchainTokenServiceProxy contract.
     * @param implementationAddress Address of the interchain token service implementation
     * @param owner Address of the owner of the proxy
     */
    constructor(
        address implementationAddress,
        address owner,
        address operator
    ) FinalProxy(implementationAddress, owner, abi.encodePacked(operator)) {}

    /**
     * @dev Override for the 'contractId' function in FinalProxy. Returns a unique identifier for this contract.
     * @return bytes32 identifier for this contract
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
