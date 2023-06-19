// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Proxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Proxy.sol';

/**
 * @title LinkerRouterProxy
 * @author Foivos Antoulinakis
 * @dev Proxy contract for the LinkerRouter contract. Inherits from the Proxy contract.
 */
contract LinkerRouterProxy is Proxy {
    /**
     * @dev Constructs the LinkerRouterProxy contract.
     * @param implementationAddress Address of the LinkerRouter implementation
     * @param owner Address of the owner of the proxy
     */
    constructor(
        address implementationAddress,
        address owner
    )
        Proxy(implementationAddress, owner, new bytes(0)) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @dev Override for the `contractId` function in Proxy. Returns a unique identifier for this contract.
     * @return bytes32 Identifier for this contract.
     */
    // solhint-disable-next-line no-empty-blocks
    function contractId() internal pure override returns (bytes32) {
        // bytes32(uint256(keccak256('remote-address-validator')) - 1)
        return 0x5d9f4d5e6bb737c289f92f2a319c66ba484357595194acb7c2122e48550eda7c;
    }
}
