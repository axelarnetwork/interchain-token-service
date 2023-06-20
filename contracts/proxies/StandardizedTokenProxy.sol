// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { FixedProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FixedProxy.sol';
import { IStandardizedToken } from '../interfaces/IStandardizedToken.sol';
import { IStandardizedTokenProxy } from '../interfaces/IStandardizedTokenProxy.sol';

/**
 * @title StandardizedTokenProxy
 * @author Foivos Antoulinakis
 * @dev Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy.
 */
contract StandardizedTokenProxy is FixedProxy, IStandardizedTokenProxy {
    // bytes32(uint256(keccak256('standardized-token')) - 1)
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf1ebb9a018916df92653eef7dc1160cdec8e19ba8f75f1500287c87894dc8db7;

    /**
     * @dev Constructs the StandardizedTokenProxy contract.
     * @param implementationAddress Address of the StandardizedToken implementation
     * @param params Initialization parameters for the StandardizedToken contract
     */
    constructor(
        address implementationAddress,
        bytes memory params
    )
        FixedProxy(implementationAddress) // solhint-disable-next-line no-empty-blocks
    {
        if (IStandardizedToken(implementationAddress).contractId() != contractId) revert WrongImplementation();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementationAddress.delegatecall(abi.encodeWithSelector(IStandardizedToken.setup.selector, params));
        if (!success) revert SetupFailed();
    }
}
