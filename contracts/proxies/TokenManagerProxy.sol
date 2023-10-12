// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

/**
 * @title TokenManagerProxy
 * @notice This contract is a proxy for token manager contracts.
 * @dev It implements ITokenManagerProxy.
 */
contract TokenManagerProxy is ITokenManagerProxy {
    IInterchainTokenService public immutable interchainTokenService;
    uint256 public immutable implementationType;
    bytes32 public immutable tokenId;

    /**
     * @dev Constructs the TokenManagerProxy contract.
     * @param interchainTokenServiceAddress_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @param tokenId_ The identifier for the token
     * @param params The initialization parameters for the token manager contract
     */
    constructor(address interchainTokenServiceAddress_, uint256 implementationType_, bytes32 tokenId_, bytes memory params) {
        interchainTokenService = IInterchainTokenService(interchainTokenServiceAddress_);
        implementationType = implementationType_;
        tokenId = tokenId_;
        address impl = _getImplementation(IInterchainTokenService(interchainTokenServiceAddress_), implementationType_);

        (bool success, ) = impl.delegatecall(abi.encodeWithSelector(TokenManagerProxy.setup.selector, params));
        if (!success) revert SetupFailed();
    }

    /**
     * @dev Returns the address of the current implementation.
     * @return impl The address of the current implementation
     */
    function implementation() public view returns (address impl) {
        impl = _getImplementation(interchainTokenService, implementationType);
    }

    /**
     * @dev Returns the implementation address from the interchain token service for the provided type.
     * @param interchainTokenServiceAddress_ The address of the interchain token service
     * @param implementationType_ The token manager type
     * @return impl The address of the implementation
     */
    function _getImplementation(
        IInterchainTokenService interchainTokenServiceAddress_,
        uint256 implementationType_
    ) internal view returns (address impl) {
        impl = interchainTokenServiceAddress_.getImplementation(implementationType_);
    }

    /**
     * @dev Setup function. Empty in this contract.
     * @param setupParams Initialization parameters
     */
    function setup(bytes calldata setupParams) external {}

    /**
     * @dev Reverts if native token is sent.
     */
    receive() external payable virtual {
        revert NativeTokenNotAccepted();
    }

    /**
     * @dev Fallback function. Delegates the call to the token manager contract.
     */
    // solhint-disable-next-line no-complex-fallback
    fallback() external payable virtual {
        address implementation_ = implementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)
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
}
