// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title InterchainTokenServiceProxy
 * @notice Proxy contract for interchain token service contracts.
 * @dev Inherits from the FinalProxy contract.
 */
contract InterchainTokenServiceProxy is Proxy {
    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');

    /**
     * @notice Constructs the InterchainTokenServiceProxy contract.
     * @param implementationAddress Address of the interchain token service implementation.
     * @param owner Address of the owner of the proxy.
     * @param setupParams Setup params for the implementation.
     */
    constructor(address implementationAddress, address owner, bytes memory setupParams) Proxy(implementationAddress, owner, setupParams) {}

    /**
     * @notice Override for the 'contractId' function in FinalProxy.
     * @dev Returns a unique identifier for this contract.
     * @return bytes32 Identifier for this contract.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
