// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { StringToAddress, AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

contract LinkerRouter is ILinkerRouter, Upgradable {
    using StringToAddress for string;
    using AddressToString for address;

    mapping(string => bytes32) public remoteAddressHashes;
    mapping(string => string) public remoteAddresses;
    address public immutable interchainTokenServiceAddress;
    bytes32 public immutable interchainTokenServiceAddressHash;
    mapping(string => bool) public supportedByGateway;

    // bytes32(uint256(keccak256('remote-address-validator')) - 1)
    bytes32 public constant override contractId = 0x5d9f4d5e6bb737c289f92f2a319c66ba484357595194acb7c2122e48550eda7c;

    constructor(address _interchainTokenServiceAddress, string[] memory trustedChainNames, string[] memory trustedAddresses) {
        if (_interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        interchainTokenServiceAddress = _interchainTokenServiceAddress;
        uint256 length = trustedChainNames.length;
        if (length != trustedAddresses.length) revert LengthMismatch();
        interchainTokenServiceAddressHash = keccak256(bytes(_lowerCase(interchainTokenServiceAddress.toString())));
        for (uint256 i; i < length; ++i) {
            addTrustedAddress(trustedChainNames[i], trustedAddresses[i]);
        }
    }

    function _lowerCase(string memory s) internal pure returns (string memory) {
        uint256 length = bytes(s).length;
        for (uint256 i; i < length; i++) {
            uint8 b = uint8(bytes(s)[i]);
            if ((b >= 65) && (b <= 70)) bytes(s)[i] = bytes1(b + uint8(32));
        }
        return s;
    }

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool) {
        string memory sourceAddressLC = _lowerCase(sourceAddress);
        bytes32 sourceAddressHash = keccak256(bytes(sourceAddressLC));
        if(sourceAddressHash == interchainTokenServiceAddressHash) {
            return true;
        }
        return sourceAddressHash == remoteAddressHashes[sourceChain];
    }

    function addTrustedAddress(string memory chain, string memory addr) public onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        if (bytes(addr).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = keccak256(bytes(_lowerCase(addr)));
        remoteAddresses[chain] = addr;
    }

    function removeTrustedAddress(string calldata chain) external onlyOwner {
        if (bytes(chain).length == 0) revert ZeroStringLength();
        remoteAddressHashes[chain] = bytes32(0);
        remoteAddresses[chain] = '';
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
            remoteAddress = interchainTokenServiceAddress.toString();
        }
    }
}
