// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FixedProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FixedProxy.sol';

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';
import { IImplementation } from '../interfaces/IImplementation.sol';

/**
 * @title InterchainTokenProxy
 * @dev Proxy contract for InterchainToken contracts. Inherits from FixedProxy.
 */
contract InterchainTokenProxy is FixedProxy {
    bytes32 private constant CONTRACT_ID = keccak256('interchain-token');

    /**
     * @dev Constructs the InterchainTokenProxy contract.
     * @param implementationAddress Address of the InterchainToken implementation
     * @param params Initialization parameters for the InterchainToken contract
     */
    constructor(address implementationAddress, bytes memory params) FixedProxy(implementationAddress) {
        if (IInterchainToken(implementationAddress).contractId() != CONTRACT_ID) revert InvalidImplementation();

        (bool success, ) = implementationAddress.delegatecall(abi.encodeWithSelector(IImplementation.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }
}
