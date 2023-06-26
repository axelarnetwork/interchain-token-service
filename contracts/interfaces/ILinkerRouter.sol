// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// General interface for upgradable contracts
interface ILinkerRouter {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    event TrustedAddressAdded(string souceChain, string sourceAddress);
    event TrustedAddressRemoved(string souceChain);
    event GatewaySupportedChainAdded(string chain);
    event GatewaySupportedChainRemoved(string chain);

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    function addTrustedAddress(string memory sourceChain, string memory sourceAddress) external;

    function removeTrustedAddress(string calldata sourceChain) external;

    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    function supportedByGateway(string calldata chainName) external view returns (bool);

    function addGatewaySupportedChains(string[] calldata chainNames) external;

    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}
