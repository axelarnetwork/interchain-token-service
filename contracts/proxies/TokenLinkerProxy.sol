// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainTokenRegistry } from '../interfaces/IInterchainTokenRegistry.sol';
import { ITokenLinkerProxy } from '../interfaces/ITokenLinkerProxy.sol';

contract TokenLinkerProxy is ITokenLinkerProxy {
    IInterchainTokenRegistry public immutable interchainTokenServiceAddress;
    TokenLinkerType public immutable implementationType;

    constructor(address interchainTokenServiceAddress_, TokenLinkerType implementationType_, bytes memory params) {
        interchainTokenServiceAddress = IInterchainTokenRegistry(interchainTokenServiceAddress_);
        implementationType = implementationType_;
        address impl = _getImplementation(IInterchainTokenRegistry(interchainTokenServiceAddress_), implementationType_);

        (bool success, ) = impl.delegatecall(abi.encodeWithSelector(TokenLinkerProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    function implementation() public view returns (address impl) {
        impl = _getImplementation(interchainTokenServiceAddress, implementationType);
    }

    function _getImplementation(
        IInterchainTokenRegistry interchainTokenServiceAddress_,
        TokenLinkerType implementationType_
    ) internal view returns (address impl) {
        impl = interchainTokenServiceAddress_.getImplementation(implementationType_);
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata setupParams) external {}

    function contractId() internal pure virtual returns (bytes32) {
        return bytes32(0);
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable virtual {
        address implementaion_ = implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}
}
