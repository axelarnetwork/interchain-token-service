// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenFactory {
    error ZeroAddress();
    error NotDistributor(address distributor);
    error NotOperator(address operator);
    error NonZeroMintAmount();
    error ApproveFailed();

    function chainNameHash() external view returns (bytes32);

    function interchainTokenSalt(bytes32 chainAddressHash_, address deployer, bytes32 salt) external view returns (bytes32);

    function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress);

    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable;

    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address additionalDistributor,
        string memory destinationChain,
        uint256 gasValue
    ) external payable;

    function canonicalInterchainTokenSalt(bytes32 chainAddressHash_, address tokenAddress) external view returns (bytes32 salt);

    function canonicalInterchainTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId);

    function deployRemoteCanonicalInterchainToken(
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
