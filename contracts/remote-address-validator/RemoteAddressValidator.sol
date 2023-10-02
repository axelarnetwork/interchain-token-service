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
    string public chainName;

    address public immutable interchainTokenServiceAddress;
    bytes32 public immutable interchainTokenServiceAddressHash;

    /**
     * @dev Store the interchain token service address as string across two immutable variables to avoid recomputation and save gas
     */
    uint256 private immutable interchainTokenServiceAddress1;
    uint256 private immutable interchainTokenServiceAddress2;

    bytes32 private constant CONTRACT_ID = keccak256('remote-address-validator');

    /**
     * @dev Constructs the RemoteAddressValidator contract, both array parameters must be equal in length
     * @param _interchainTokenServiceAddress Address of the interchain token service
     */
    constructor(address _interchainTokenServiceAddress, string memory chainName_) {
        if (_interchainTokenServiceAddress == address(0)) revert ZeroAddress();

        interchainTokenServiceAddress = _interchainTokenServiceAddress;

        string memory interchainTokenServiceAddressString = interchainTokenServiceAddress.toString();
        interchainTokenServiceAddressHash = keccak256(bytes(interchainTokenServiceAddressString));

        uint256 p1;
        uint256 p2;

        assembly {
            p1 := mload(add(interchainTokenServiceAddressString, 32))
            p2 := mload(add(interchainTokenServiceAddressString, 64))
        }

        interchainTokenServiceAddress1 = p1;
        interchainTokenServiceAddress2 = p2;

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
     * @dev Return the interchain token service address as a string by constructing it from the two immutable variables caching it
     */
    function _interchainTokenServiceAddressString() internal view returns (string memory interchainTokenServiceAddressString) {
        interchainTokenServiceAddressString = new string(42);

        uint256 p1 = interchainTokenServiceAddress1;
        uint256 p2 = interchainTokenServiceAddress2;

        assembly {
            mstore(add(interchainTokenServiceAddressString, 32), p1)
            mstore(add(interchainTokenServiceAddressString, 64), p2)
        }
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

        if (sourceAddressHash == interchainTokenServiceAddressHash) {
            return true;
        }

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
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName_ Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName_) external view returns (string memory remoteAddress) {
        remoteAddress = remoteAddresses[chainName_];

        if (bytes(remoteAddress).length == 0) {
            remoteAddress = _interchainTokenServiceAddressString();
        }
    }
}
