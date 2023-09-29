// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IRemoteAddressValidator } from '../interfaces/IRemoteAddressValidator.sol';
import { AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

/**
 * @title RemoteAddressValidator
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
contract RemoteAddressValidator is IRemoteAddressValidator, Upgradable {
    using AddressToString for address;

    mapping(string => bytes32) public remoteAddressHashes;
    mapping(string => string) public remoteAddresses;
    mapping(string => bool) public supportedByGateway;
    string public chainName;

    bytes32 private constant CONTRACT_ID = keccak256('remote-address-validator');

    /**
     * @dev Constructs the RemoteAddressValidator contract, both array parameters must be equal in length.
     * @param chainName_ The name of the current chain.
     */
    constructor(string memory chainName_) {
        if (bytes(chainName_).length == 0) revert ZeroStringLength();
        chainName = chainName_;
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    function _setup(bytes calldata params) internal override {
        (string[] memory trustedChainNames, string[] memory trustedAddresses) = abi.decode(params, (string[], string[]));
        uint256 length = trustedChainNames.length;

        if (length != trustedAddresses.length) revert LengthMismatch();

        for (uint256 i; i < length; ++i) {
            addTrustedAddress(trustedChainNames[i], trustedAddresses[i]);
        }
    }

    /**
     * @dev Converts a string to lower case
     * @param s Input string to be converted
     * @return string lowercase version of the input string
     */
    function _lowerCase(string memory s) internal pure returns (string memory) {
        uint256 length = bytes(s).length;
        uint8 b;
        for (uint256 i; i < length; ++i) {
            b = uint8(bytes(s)[i]);
            if ((b >= 65) && (b <= 90)) bytes(s)[i] = bytes1(b + uint8(32));
        }

        return s;
    }

    /**
     * @dev Validates that the sender is a valid interchain token service address
     * @param sourceChain Source chain of the transaction
     * @param sourceAddress Source address of the transaction
     * @return bool true if the sender is validated, false otherwise
     */
    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool) {
        string memory sourceAddressNormalized = _lowerCase(sourceAddress);
        bytes32 sourceAddressHash = keccak256(bytes(sourceAddressNormalized));

        return sourceAddressHash == remoteAddressHashes[sourceChain];
    }

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param sourceChain Chain name of the interchain token service
     * @param sourceAddress Interchain token service address to be added
     */
    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) public onlyOwner {
        if (bytes(sourceChain).length == 0) revert ZeroStringLength();
        if (bytes(sourceAddress).length == 0) revert ZeroStringLength();

        remoteAddressHashes[sourceChain] = keccak256(bytes(_lowerCase(sourceAddress)));
        remoteAddresses[sourceChain] = sourceAddress;

        emit TrustedAddressAdded(sourceChain, sourceAddress);
    }

    /**
     * @dev Removes a trusted interchain token service address
     * @param sourceChain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata sourceChain) external onlyOwner {
        if (bytes(sourceChain).length == 0) revert ZeroStringLength();

        remoteAddressHashes[sourceChain] = bytes32(0);
        remoteAddresses[sourceChain] = '';

        emit TrustedAddressRemoved(sourceChain);
    }

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        string calldata chainName_;
        for (uint256 i; i < length; ++i) {
            chainName_ = chainNames[i];
            supportedByGateway[chainName_] = true;

            emit GatewaySupportedChainAdded(chainName_);
        }
    }

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        string calldata chainName_;

        for (uint256 i; i < length; ++i) {
            chainName_ = chainNames[i];
            supportedByGateway[chainName_] = false;

            emit GatewaySupportedChainRemoved(chainName_);
        }
    }

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName_ Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName_) external view returns (string memory remoteAddress) {
        remoteAddress = remoteAddresses[chainName_];

        if (bytes(remoteAddress).length == 0) {
            revert UntrustedChain();
        }
    }
}
