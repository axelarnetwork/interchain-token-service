// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IProxy.sol';
import { BaseProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/BaseProxy.sol';

import { IBaseTokenManager } from '../interfaces/IBaseTokenManager.sol';
import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';
import { ITokenManagerImplementation } from '../interfaces/ITokenManagerImplementation.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';

/**
 * @title TokenManagerProxy
 * @notice This contract is a proxy for token manager contracts.
 * @dev This contract implements BaseProxy and ITokenManagerProxy.
 */
contract TokenManagerProxy is BaseProxy, ITokenManagerType, ITokenManagerProxy {
    bytes32 private constant CONTRACT_ID = keccak256('token-manager');

    address public immutable interchainTokenService;
    uint256 public immutable implementationType;
    bytes32 public immutable interchainTokenId;
    address public immutable tokenAddress;

    /**
     * @notice Constructs the TokenManagerProxy contract.
     * @param interchainTokenService_ The address of the interchain token service.
     * @param implementationType_ The token manager type.
     * @param tokenId The identifier for the token.
     * @param params The initialization parameters for the token manager contract.
     */
    constructor(address interchainTokenService_, uint256 implementationType_, bytes32 tokenId, bytes memory params) payable {
        if (interchainTokenService_ == address(0)) revert ZeroAddress();

        interchainTokenService = interchainTokenService_;
        implementationType = implementationType_;
        interchainTokenId = tokenId;

        address implementation_ = _tokenManagerImplementation(interchainTokenService_, implementationType_);
        if (implementation_ == address(0)) revert InvalidImplementation();

        // If the implementation type is NATIVE_INTERCHAIN_TOKEN, deploy the token
        if (implementationType_ == uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            // Parse the parameters to get the token deploy info
            (bytes memory operator, string memory name, string memory symbol, uint8 decimals) = IBaseTokenManager(implementation_)
                .getTokenDeployInfoFromParams(params);

            // Get the deployer address from the interchain token service
            address interchainTokenDeployer = IInterchainTokenService(interchainTokenService).interchainTokenDeployer();

            // Call the interchain token deployer to deploy the token
            (bool deploySuccess, bytes memory returnData) = interchainTokenDeployer.delegatecall(
                abi.encodeWithSelector(IInterchainTokenDeployer.deployInterchainToken.selector, tokenId, name, symbol, decimals)
            );
            if (!deploySuccess) {
                revert InterchainTokenDeploymentFailed(returnData);
            }

            // Get and save the address
            address tokenAddress_;
            assembly {
                tokenAddress_ := mload(add(returnData, 0x20))
            }
            tokenAddress = tokenAddress_;

            // Setup the token manager
            // The setup will add operator as the minter
            bytes memory setupParams = abi.encode(operator, tokenAddress_);

            (bool success, ) = implementation_.delegatecall(abi.encodeWithSelector(IProxy.setup.selector, setupParams));
            if (!success) revert SetupFailed();
        } else {
            // For other token manager types
            // Check token manager type is supported
            bool success;
            bytes memory returnData;
            (success, returnData) = implementation_.delegatecall(
                abi.encodeWithSelector(ITokenManager.ensureSupported.selector, tokenAddress, implementationType_)
            );
            if (!success) revert NotSupported(returnData);

            // Get the token address from the params
            tokenAddress = IBaseTokenManager(implementation_).getTokenAddressFromParams(params);

            // Setup the token manager
            (success, ) = implementation_.delegatecall(abi.encodeWithSelector(IProxy.setup.selector, params));
            if (!success) revert SetupFailed();
        }
    }

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id.
     */
    function contractId() internal pure override returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Returns implementation type and token address.
     * @return implementationType_ The implementation type.
     * @return tokenAddress_ The token address.
     */
    function getImplementationTypeAndTokenAddress() external view returns (uint256 implementationType_, address tokenAddress_) {
        implementationType_ = implementationType;
        tokenAddress_ = tokenAddress;
    }

    /**
     * @notice Returns the address of the current implementation.
     * @return implementation_ The address of the current implementation.
     */
    function implementation() public view override(BaseProxy, IProxy) returns (address implementation_) {
        implementation_ = _tokenManagerImplementation(interchainTokenService, implementationType);
    }

    /**
     * @notice Returns the implementation address from the interchain token service for the provided type.
     * @param interchainTokenService_ The address of the interchain token service.
     * @param implementationType_ The token manager type.
     * @return implementation_ The address of the implementation.
     */
    function _tokenManagerImplementation(
        address interchainTokenService_,
        uint256 implementationType_
    ) internal view returns (address implementation_) {
        implementation_ = ITokenManagerImplementation(interchainTokenService_).tokenManagerImplementation(implementationType_);
    }
}
