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

    event TrustedAddressAdded(string sourceChain, string sourceAddress);
    event TrustedAddressRemoved(string sourceChain);

    /**
     * @notice Returns the interchain token address
     */
    function chainName() external view returns (string memory);

    /**
     * @notice Returns the interchain token address
     */
    function interchainTokenServiceAddress() external view returns (address);

    /**
     * @notice Returns the interchain token address to string to lower case hash, which is used to compare with incoming calls.
     */
    function interchainTokenServiceAddressHash() external view returns (bytes32);

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
}
