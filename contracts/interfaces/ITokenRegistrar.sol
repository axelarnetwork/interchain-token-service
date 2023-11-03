// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenRegistrar {
    error ZeroAddress();
    error NotDistributor(address distributor);
    error NotOperator(address operator);
    error NonZeroMintAmount();
    error ApproveFailed();

    function chainNameHash() external view returns (bytes32);

    function standardizedTokenSalt(bytes32 chainAddressHash_, address deployer, bytes32 salt) external view returns (bytes32);

    function standardizedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress);

    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor,
        address operator
    ) external payable;

    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address additionalDistributor,
        address optionalOperator,
        string memory destinationChain,
        uint256 gasValue
    ) external payable;

    function canonicalTokenSalt(bytes32 chainAddressHash_, address tokenAddress) external view returns (bytes32 salt);

    function canonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId);

    function deployRemoteCanonicalToken(
        string calldata originalChainName,
        address originalAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable;

    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        uint256 gasValue
    ) external payable;

    function tokenTransferFrom(bytes32 tokenId, uint256 amount) external payable;

    function tokenApprove(bytes32 tokenId, uint256 amount) external payable;
}
