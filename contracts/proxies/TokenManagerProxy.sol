// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

// Inherit from FixedProxy from gmp sdk
contract TokenManagerProxy is ITokenManagerProxy {
    IInterchainTokenService public immutable interchainTokenServiceAddress;
    uint256 public immutable implementationType;
    bytes32 public immutable tokenId;

    constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId_, bytes memory params) {
        interchainTokenServiceAddress = IInterchainTokenService(interchainTokenServiceAddress_);
        implementationType = implementationType_;
        tokenId = tokenId_;
        address impl = _getImplementation(IInterchainTokenService(interchainTokenServiceAddress_), implementationType_);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = impl.delegatecall(abi.encodeWithSelector(TokenManagerProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    function implementation() public view returns (address impl) {
        impl = _getImplementation(interchainTokenServiceAddress, implementationType);
    }

    function _getImplementation(
        IInterchainTokenService interchainTokenServiceAddress_,
        uint256 implementationType_
    ) internal view returns (address impl) {
        impl = interchainTokenServiceAddress_.getImplementation(implementationType_);
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata setupParams) external {}

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
