// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FixedProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FixedProxy.sol';
import { IStandardizedToken } from '../interfaces/IStandardizedToken.sol';
import { IStandardizedTokenProxy } from '../interfaces/IStandardizedTokenProxy.sol';

/**
 * @title StandardizedTokenProxy
 * @dev Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy.
 */
contract StandardizedTokenProxy is FixedProxy, IStandardizedTokenProxy {
    bytes32 public constant contractId = keccak256('standardized-token');

    /**
     * @dev Constructs the StandardizedTokenProxy contract.
     * @param implementationAddress Address of the StandardizedToken implementation
     * @param params Initialization parameters for the StandardizedToken contract
     */
    constructor(address implementationAddress, bytes memory params) FixedProxy(implementationAddress) {
        if (IStandardizedToken(implementationAddress).contractId() != contractId) revert WrongImplementation();

        (bool success, ) = implementationAddress.delegatecall(abi.encodeWithSelector(IStandardizedToken.setup.selector, params));
        if (!success) revert SetupFailed();
    }
}
