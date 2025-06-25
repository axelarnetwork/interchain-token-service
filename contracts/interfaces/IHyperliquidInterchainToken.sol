// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IHyperliquidInterchainToken interface
 * @dev Interface for Hyperliquid-specific functionality only.
 * Note: This interface does not extend IInterchainToken to avoid override conflicts
 * since InterchainToken functions are not virtual.
 */
interface IHyperliquidInterchainToken {
    /**
     * @notice Setup function to initialize contract parameters for Hyperliquid tokens.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function initHyperliquid(
        bytes32 tokenId_,
        address minter,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Gets the deployer address stored in slot 0
     * @return deployer The address of the deployer
     */
    function getDeployer() external view returns (address deployer);

    /**
     * @notice Allows updating the deployer address
     * @dev Only the interchain token service can call this function
     * @param newDeployer The new deployer address to set
     */
    function updateDeployer(address newDeployer) external;
}
