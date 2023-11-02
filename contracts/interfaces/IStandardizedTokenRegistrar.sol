// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStandardizedTokenRegistrar {
    error ZeroAddress();
    error NotDistributor(address distributor);
    error NotOperator(address operator);
    error NonZeroMintAmount();

    function chainNameHash() external view returns (bytes32);

    function standardizedTokenSalt(address deployer, bytes32 salt) external view returns (bytes32);

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

    function deployRemoteStandarizedToken(
        bytes32 salt,
        address additionalDistributor,
        address optionalOperator,
        uint256 mintAmount,
        string memory destinationChain,
        uint256 gasValue
    ) external payable;
}
