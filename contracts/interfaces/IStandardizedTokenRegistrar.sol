// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStandardizedTokenRegistrar {
    error ZeroAddress();
    error NotDistributor(address distributor);
    error NotOperator(address operator);

    function chainName() external view returns (string memory);

    function chainNameHash() external view returns (bytes32);

    function getStandardizedTokenSalt(address deployer, bytes32 salt) external view returns (bytes32);

    function getStandardizedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    function getStandardizedTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress);

    function deployStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable;

    function deployRemoteStandarizedToken(
        bytes32 salt,
        address additionalDistributor,
        address optionalOperator,
        string memory destinationChain,
        uint256 gasValue
    ) external payable;
}
