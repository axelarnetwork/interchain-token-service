// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenStandard } from './IInterchainTokenStandard.sol';
import { IMinter } from './IMinter.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @title IInterchainToken interface
 * @dev Extends IInterchainTokenStandard and IMinter.
 */
interface IInterchainToken is IInterchainTokenStandard, IMinter, IERC20MintableBurnable, IERC20Named {
    error InterchainTokenServiceAddressZero();
    error TokenIdZero();
    error TokenNameEmpty();
    error TokenSymbolEmpty();
    error AlreadyInitialized();

    /**
     * @notice Getter for the interchain token service contract.
     * @dev Needs to be overwitten.
     * @return interchainTokenServiceAddress The interchain token service address.
     */
    function interchainTokenService() external view returns (address interchainTokenServiceAddress);

    /**
     * @notice Getter for the tokenId used for this token.
     * @dev Needs to be overwitten.
     * @return tokenId_ The tokenId for this token.
     */
    function interchainTokenId() external view returns (bytes32 tokenId_);

    /**
     * @notice Setup function to initialize contract parameters.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbopl of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function init(bytes32 tokenId_, address minter, string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals) external;

    /**
     * @notice Setup function to initialize contract parameters with deployer tracking.
     * @dev NEW FUNCTION: This version stores the deployer address in slot 0 for Hyperliquid compatibility.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The decimals of the token.
     * @param deployer The address of the deployer (stored in slot 0).
     */
    function initWithDeployer(
        bytes32 tokenId_, 
        address minter, 
        string calldata tokenName, 
        string calldata tokenSymbol, 
        uint8 tokenDecimals,
        address deployer
    ) external;

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return The address of the deployer
     */
    function getDeployer() external view returns (address);
}
