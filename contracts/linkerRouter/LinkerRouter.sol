// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { StringToAddress, AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

contract LinkerRouter is ILinkerRouter, Upgradable {
    using StringToAddress for string;
    using AddressToString for address;

    bytes32 public immutable addressHash;
    mapping(string => bytes32) public remoteAddressHashes;
    mapping(string => string) public remoteAddresses;
    address public immutable interChainTokenServiceAddress;
    mapping(string => bool) public supportedByGateway;

    // bytes32(uint256(keccak256('remote-address-validator')) - 1)
    bytes32 public constant override contractId = 0x5d9f4d5e6bb737c289f92f2a319c66ba484357595194acb7c2122e48550eda7c;

    constructor(address tokenLinkerAddress_, string[] memory trustedChainNames, string[] memory trustedAddresses) {
        if (tokenLinkerAddress_ == address(0)) revert ZeroAddress();
        interChainTokenServiceAddress = tokenLinkerAddress_;
        uint256 length = trustedChainNames.length;
        if (length != trustedAddresses.length) revert LengthMismatch();
        addressHash = keccak256(bytes(_lowerCase(interChainTokenServiceAddress.toString())));
        for (uint256 i; i < length; ++i) {
            string memory chainName = trustedChainNames[i];
            if (bytes(chainName).length == 0) revert ZeroStringLength();
            string memory remoteAddress = _lowerCase(trustedAddresses[i]);
            if (bytes(remoteAddress).length == 0) revert ZeroStringLength();
            remoteAddresses[chainName] = remoteAddress;
            bytes32 remoteAddressHash = keccak256(bytes(remoteAddress));
            remoteAddressHashes[chainName] = remoteAddressHash;
        }
    }

    function _lowerCase(string memory s) internal pure returns (string memory) {
        uint256 length = bytes(s).length;
        bytes memory tmp = bytes(s);
        for (uint256 i; i < length; i++) {
            uint8 b = uint8(tmp[i]);
            if ((b >= 65) && (b <= 70)) tmp[i] = bytes1(b + uint8(32));
        }
        return s;
    }

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool) {
        string memory sourceAddressLC = _lowerCase(sourceAddress);
        bytes32 sourceAddressHash = keccak256(bytes(sourceAddressLC));
        bytes32 remoteAddressHash = remoteAddressHashes[sourceChain];
        if (remoteAddressHash == bytes32(0)) {
            if (sourceAddressHash == addressHash) return true;
        } else {
            if (sourceAddressHash == remoteAddressHash) return true;
        }
        return false;
    }

    function addTrustedAddress(string calldata sourceChain, string calldata sourceAddress) external onlyOwner {
        remoteAddressHashes[sourceChain] = keccak256(bytes(_lowerCase(sourceAddress)));
        remoteAddresses[sourceChain] = sourceAddress;
    }

    function removeTrustedAddress(string calldata sourceChain) external onlyOwner {
        remoteAddressHashes[sourceChain] = bytes32(0);
        remoteAddresses[sourceChain] = '';
    }

    function addGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            supportedByGateway[chainNames[i]] = true;
        }
    }

    function removeGatewaySupportedChains(string[] calldata chainNames) external onlyOwner {
        uint256 length = chainNames.length;
        for (uint256 i; i < length; ++i) {
            supportedByGateway[chainNames[i]] = false;
        }
    }

    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress) {
        remoteAddress = remoteAddresses[chainName];
        if (bytes(remoteAddress).length == 0) {
            remoteAddress = interChainTokenServiceAddress.toString();
        }
    }
}
