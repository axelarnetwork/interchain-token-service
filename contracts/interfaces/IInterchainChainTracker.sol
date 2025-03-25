// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInterchainChainTracker {
    event TrustedChainSet(string chainName);
    event TrustedChainRemoved(string chainName);
    event ItsHubAddressSet(string hubAddress);

    function itsHubAddress() external view returns (string memory hubAddress);

    function itsHubAddressHash() external view returns (bytes32 hubAddressHash);

    function isTrustedChain(string memory chain) external view returns (bool trusted);
}
