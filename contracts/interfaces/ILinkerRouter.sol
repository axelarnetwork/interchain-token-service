// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface ILinkerRouter {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    event TrustedAddressAdded(string, string);
    event TrustedAddressRemoved(string);
    event GatewaySupportedChainAdded(string);
    event GatewaySupportedChainRemoved(string);

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    function removeTrustedAddress(string calldata sourceChain) external;

    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    function supportedByGateway(string calldata chainName) external view returns (bool);

    function addGatewaySupportedChains(string[] calldata chainNames) external;

    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}
