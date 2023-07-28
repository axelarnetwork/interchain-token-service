// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { ITokenManagerGetter } from '../interfaces/ITokenManagerGetter.sol';

/**
 * @title TokenManagerProxy
 * @dev This contract is a proxy for token manager contracts. It implements ITokenManagerProxy and
 * inherits from FixedProxy from the gmp sdk repo
 */
contract TokenManagerProxy is ITokenManagerProxy {
    ITokenManagerGetter internal immutable tokenManagerGetter;
    uint256 public immutable implementationType;
    bytes32 public immutable tokenId;

    /**
     * @dev Constructs the TokenManagerProxy contract.
     * @param implementationType_ The token manager type
     * @param tokenId_ The identifier for the token
     * @param params The initialization parameters for the token manager contract
     */
    constructor(uint256 implementationType_, address interchainTokenServiceAddress, bytes32 tokenId_, bytes memory params) {
        IInterchainTokenService interchainTokenService = IInterchainTokenService(interchainTokenServiceAddress);
        implementationType = implementationType_;
        tokenId = tokenId_;
        address tokenManagerGetterAddress = interchainTokenService.tokenManagerGetter();
        tokenManagerGetter = ITokenManagerGetter(tokenManagerGetterAddress);
        address impl = _getImplementation(tokenManagerGetter, implementationType_);

        (bool success, ) = impl.delegatecall(abi.encodeWithSelector(TokenManagerProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @dev Returns the address of the current implementation.
     * @return impl The address of the current implementation
     */
    function implementation() public view returns (address impl) {
        impl = _getImplementation(tokenManagerGetter, implementationType);
    }

    /**
     * @dev Returns the implementation address from the interchain token service for the provided type.
     * @param tokenManagerGetter_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @return impl The address of the implementation
     */
    function _getImplementation(ITokenManagerGetter tokenManagerGetter_, uint256 implementationType_) internal view returns (address impl) {
        impl = tokenManagerGetter_.getImplementation(implementationType_);
    }

    /**
     * @dev Setup function. Empty in this contract.
     * @param setupParams Initialization parameters
     */
    function setup(bytes calldata setupParams) external {}

    /**
     * @dev Fallback function. Delegates the call to the token manager contract.
     */
    // solhint-disable-next-line no-complex-fallback
    fallback() external payable virtual {
        address implementaion_ = implementation();

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

    /**
     * @dev Receive function which allows this contract to receive ether.
     */
    receive() external payable virtual {}
}
