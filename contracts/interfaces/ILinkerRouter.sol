// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface ILinkerRouter {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    function addTrustedAddress(string calldata sourceChain, string calldata sourceAddress) external;

    function removeTrustedAddress(string calldata sourceChain) external;

    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    function supportedByGateway(string calldata chainName) external view returns (bool);

    function addGatewaySupportedChains(string[] calldata chainNames) external;

    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}
