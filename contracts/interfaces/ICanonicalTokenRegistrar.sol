// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICanonicalTokenRegistrar {
    error ZeroAddress();

    function chainNameHash() external view returns (bytes32);

    function getCanonicalTokenSalt(address tokenAddress) external view returns (bytes32 salt);

    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId);

    function deployAndRegisterRemoteCanonicalToken(bytes32 salt, string calldata destinationChain, uint256 gasValue) external payable;
}
