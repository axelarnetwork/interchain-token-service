// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IRemoteAddressValidator
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
interface IRemoteAddressValidator {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();
    error UntrustedChain();

    event TrustedAddressAdded(string sourceChain, string sourceAddress);
    event TrustedAddressRemoved(string sourceChain);
    event GatewaySupportedChainAdded(string chain);
    event GatewaySupportedChainRemoved(string chain);

    /**
     * @notice Returns the interchain token address
     */
    function chainName() external view returns (string memory);

    /**
     * @dev Validates that the sender is a valid interchain token service address
     * @param sourceChain Source chain of the transaction
     * @param sourceAddress Source address of the transaction
     * @return bool true if the sender is validated, false otherwise
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param sourceChain Chain name of the interchain token service
     * @param sourceAddress Interchain token service address to be added
     */
    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    /**
     * @dev Removes a trusted interchain token service address
     * @param sourceChain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata sourceChain) external;

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    /**
     * @notice Returns true if the gateway delivers token to this chain.
     * @param chainName Name of the chain
     */
    function supportedByGateway(string calldata chainName) external view returns (bool);

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external;

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}
