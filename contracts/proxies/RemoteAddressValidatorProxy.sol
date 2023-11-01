// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title RemoteAddressValidatorProxy
 * @notice Proxy contract for the RemoteAddressValidator contract.
 * @dev Inherits from the Proxy contract.
 */
contract RemoteAddressValidatorProxy is Proxy {
    bytes32 private constant CONTRACT_ID = keccak256('remote-address-validator');

    /**
     * @notice Constructs the RemoteAddressValidatorProxy contract.
     * @param implementationAddress Address of the RemoteAddressValidator implementation.
     * @param owner Address of the owner of the proxy.
     * @param params The params to be passed to the _setup function of the implementation.
     */
    constructor(address implementationAddress, address owner, bytes memory params) Proxy(implementationAddress, owner, params) {}

    /**
     * @notice Override for the `contractId` function in Proxy.
     * @dev Returns a unique identifier for this contract.
     * @return bytes32 Identifier for this contract.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
