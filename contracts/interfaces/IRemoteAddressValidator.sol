// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IContractIdentifier } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IContractIdentifier.sol';

/**
 * @title IRemoteAddressValidator Interface
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
interface IRemoteAddressValidator is IContractIdentifier {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();
    error UntrustedChain();

    event TrustedAddressAdded(string sourceChain, string sourceAddress);
    event TrustedAddressRemoved(string sourceChain);

    /**
     * @notice Returns the name of the current chain.
     * @return string The name of the current chain.
     */
    function chainName() external view returns (string memory);

    /**
     * @dev Validates that the sender is a valid interchain token service address.
     * @param sourceChain Source chain of the transaction.
     * @param sourceAddress Source address of the transaction.
     * @return bool True if the sender is validated, false otherwise.
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    /**
     * @dev Adds a trusted interchain token service address for the specified chain.
     * @param sourceChain Chain name of the interchain token service.
     * @param sourceAddress Interchain token service address to be added.
     */
    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    /**
     * @dev Removes a trusted interchain token service address.
     * @param sourceChain Chain name of the interchain token service to be removed.
     */
    function removeTrustedAddress(string calldata sourceChain) external;

    /**
     * @dev Fetches the interchain token service address for the specified chain.
     * @param chainName_ Name of the chain.
     * @return remoteAddress Interchain token service address for the specified chain.
     */
    function getRemoteAddress(string calldata chainName_) external view returns (string memory remoteAddress);
}
