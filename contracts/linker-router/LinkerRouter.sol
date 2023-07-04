// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

/**
 * @title LinkerRouter
 * @dev Manages and validates remote addresses, keeps track of addresses supported by the Axelar gateway contract
 */
contract LinkerRouter is ILinkerRouter, Upgradable {
    using AddressToString for address;

    mapping(string => bytes32) public remoteAddressHashes;
    mapping(string => string) public remoteAddresses;
    address public immutable interchainTokenServiceAddress;
    bytes32 public immutable interchainTokenServiceAddressHash;
    mapping(string => bool) public supportedByGateway;

    bytes32 public constant override contractId = keccak256('remote-address-validator');

    /**
     * @dev Constructs the LinkerRouter contract, both array parameters must be equal in length
     * @param _interchainTokenServiceAddress Address of the interchain token service
     */
    constructor(address _interchainTokenServiceAddress) {
        if (_interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        interchainTokenServiceAddress = _interchainTokenServiceAddress;
        interchainTokenServiceAddressHash = keccak256(bytes(_lowerCase(interchainTokenServiceAddress.toString())));
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
        for (uint256 i; i < length; i++) {
            uint8 b = uint8(bytes(s)[i]);
            if ((b >= 65) && (b <= 70)) bytes(s)[i] = bytes1(b + uint8(32));
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
        string memory sourceAddressLC = _lowerCase(sourceAddress);
        bytes32 sourceAddressHash = keccak256(bytes(sourceAddressLC));
        if (sourceAddressHash == interchainTokenServiceAddressHash) {
            return true;
        }
        return sourceAddressHash == remoteAddressHashes[sourceChain];
    }

    /**
     * @dev Adds a trusted interchain token service address for the specified chain
     * @param chain Chain name of the interchain token service
     * @param addr Interchain token service address to be added
     */
    function addTrustedAddress(string memory chain, string memory addr) public onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        if (bytes(addr).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = keccak256(bytes(_lowerCase(addr)));
        remoteAddresses[chain] = addr;
        emit TrustedAddressAdded(chain, addr);
    }

    /**
     * @dev Removes a trusted interchain token service address
     * @param chain Chain name of the interchain token service to be removed
     */
    function removeTrustedAddress(string calldata chain) external onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = bytes32(0);
        remoteAddresses[chain] = '';
        emit TrustedAddressRemoved(chain);
    }

    /**
     * @dev Adds chains that are supported by the Axelar gateway
     * @param chainNames List of chain names to be added as supported
     */
    function addGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            string calldata chainName = chainNames[i];
            supportedByGateway[chainName] = true;
            emit GatewaySupportedChainAdded(chainName);
        }
    }

    /**
     * @dev Removes chains that are no longer supported by the Axelar gateway
     * @param chainNames List of chain names to be removed as supported
     */
    function removeGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            string calldata chainName = chainNames[i];
            supportedByGateway[chainName] = false;
            emit GatewaySupportedChainRemoved(chainName);
        }
    }

    /**
     * @dev Fetches the interchain token service address for the specified chain
     * @param chainName Name of the chain
     * @return remoteAddress Interchain token service address for the specified chain
     */
    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress) {
        remoteAddress = remoteAddresses[chainName];
        if (bytes(remoteAddress).length == 0) {
            remoteAddress = interchainTokenServiceAddress.toString();
        }
    }
}
