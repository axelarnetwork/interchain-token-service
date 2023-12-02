// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenFactory Interface
 * @notice This interface defines functions for deploying new interchain tokens and managing their token managers.
 */
interface IInterchainTokenFactory {
    error ZeroAddress();
    error InvalidChainName();
    error NotDistributor(address distributor);
    error NotOperator(address operator);
    error InsufficientBalance(bytes32 tokenId, address deployer, uint256 balance);
    error ApproveFailed();
    error GatewayToken(address tokenAddress);

    /**
     * @notice Returns the hash of the chain name.
     * @return bytes32 The hash of the chain name.
     */
    function chainNameHash() external view returns (bytes32);

    /**
     * @notice Calculates the salt for an interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param deployer The address of the deployer.
     * @param salt A unique identifier to generate the salt.
     * @return bytes32 The calculated salt for the interchain token.
     */
    function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) external view returns (bytes32);

    /**
     * @notice Computes the ID for an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenId The ID of the interchain token.
     */
    function interchainTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId);

    /**
     * @notice Retrieves the address of an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenAddress The address of the interchain token.
     */
    function interchainTokenAddress(address deployer, bytes32 salt) external view returns (address tokenAddress);

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @param salt The unique salt for deploying the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals for the token.
     * @param initialSupply The amount of tokens to mint initially (can be zero).
     * @param distributor The address to receive the initially minted tokens.
     */
    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply,
        address distributor
    ) external payable;

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param originalChainName The name of the chain where the token originally exists.
     * @param salt The unique salt for deploying the token.
     * @param distributor The address to distribute the token on the destination chain.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The amount of gas to send for the deployment.
     */
    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address distributor,
        string memory destinationChain,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Calculates the salt for a canonical interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param tokenAddress The address of the token.
     * @return salt The calculated salt for the interchain token.
     */
    function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) external view returns (bytes32 salt);

    /**
     * @notice Computes the ID for a canonical interchain token based on its address.
     * @param tokenAddress The address of the canonical interchain token.
     * @return tokenId The ID of the canonical interchain token.
     */
    function canonicalInterchainTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    /**
     * @notice Registers a canonical token as an interchain token and deploys its token manager.
     * @param tokenAddress The address of the canonical token.
     * @return tokenId The unique identifier of the registered interchain token.
     */
    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId);

    /**
     * @notice Deploys a canonical interchain token on a remote chain.
     * @param originalChain The name of the chain where the token originally exists.
     * @param originalTokenAddress The address of the original token on the original chain.
     * @param destinationChain The name of the chain where the token will be deployed.
     * @param gasValue The gas amount to be sent for deployment.
     */
    function deployRemoteCanonicalInterchainToken(
        string calldata originalChain,
        address originalTokenAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Transfers an interchain token to a specified destination chain and address.
     * @param tokenId The identifier of the interchain token.
     * @param destinationChain The name of the destination chain.
     * @param destinationAddress The address on the destination chain to receive the token.
     * @param amount The amount of tokens to transfer.
     * @param gasValue The amount of gas to send for the transfer.
     */
    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        uint256 gasValue
    ) external payable;

    /**
     * @notice Allows tokens to be transferred from the sender to the contract.
     * @param tokenId The identifier of the interchain token.
     * @param amount The amount of tokens to transfer.
     */
    function tokenTransferFrom(bytes32 tokenId, uint256 amount) external payable;

    /**
     * @notice Approves a specified amount of tokens to the token manager.
     * @param tokenId The identifier of the interchain token.
     * @param amount The amount of tokens to approve.
     */
    function tokenApprove(bytes32 tokenId, uint256 amount) external payable;
}
