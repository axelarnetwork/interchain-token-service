// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { FixedProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FixedProxy.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract TokenProxy is FixedProxy {
    constructor(
        address implementationAddress,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address owner
    )
        FixedProxy(implementationAddress) // solhint-disable-next-line no-empty-blocks;
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementationAddress.delegatecall(
            abi.encodeWithSelector(IERC20BurnableMintable.setup.selector, name, symbol, decimals, owner)
        );
        if (!success) revert SetupFailed();
    }
}
