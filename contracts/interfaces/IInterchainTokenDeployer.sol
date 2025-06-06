// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenDeployer
 * @notice This interface is used to deploy new instances of the InterchainTokenProxy contract.
 */
interface IInterchainTokenDeployer {
    error AddressZero();
    error TokenIdZero();
    error TokenNameEmpty();
    error TokenSymbolEmpty();
    error TokenDeploymentFailed();

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract.
     * @param tokenId tokenId of the token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @return tokenAddress Address of the deployed token.
     */
    function deployInterchainToken(
        bytes32 tokenId,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external payable returns (address tokenAddress);
}
