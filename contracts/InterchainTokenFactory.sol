// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

import { IInterchainTokenService } from './interfaces/IInterchainTokenService.sol';
import { IInterchainTokenFactory } from './interfaces/IInterchainTokenFactory.sol';
import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IInterchainToken } from './interfaces/IInterchainToken.sol';

/**
 * @title InterchainTokenFactory
 * @notice This contract is responsible for deploying new interchain tokens and managing their token managers.
 */
contract InterchainTokenFactory is IInterchainTokenFactory, ITokenManagerType, Multicall, Upgradable {
    using AddressBytes for bytes;
    using AddressBytes for address;
    using SafeTokenTransfer for IInterchainToken;
    using SafeTokenTransferFrom for IInterchainToken;
    using SafeTokenCall for IInterchainToken;

    IInterchainTokenService public immutable service;
    bytes32 public immutable chainNameHash;
    IAxelarGateway public immutable gateway;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-factory');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_SALT = keccak256('canonical-token-salt');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('interchain-token-salt');
    address private constant TOKEN_FACTORY_DEPLOYER = address(0);

    /**
     * @notice Constructs the InterchainTokenFactory contract.
     * @param interchainTokenServiceAddress The address of the interchain token service.
     */
    constructor(address interchainTokenServiceAddress) {
        if (interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        service = IInterchainTokenService(interchainTokenServiceAddress);

        chainNameHash = service.chainNameHash();
        gateway = service.gateway();
    }

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id of this contract.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Calculates the salt for an interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param deployer The address of the deployer.
     * @param salt A unique identifier to generate the salt.
     * @return bytes32 The calculated salt for the interchain token.
     */
    function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, chainNameHash_, deployer, salt));
    }

    /**
     * @notice Calculates the salt for a canonical interchain token.
     * @param chainNameHash_ The hash of the chain name.
     * @param tokenAddress The address of the token.
     * @return salt The calculated salt for the interchain token.
     */
    function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) public pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_SALT, chainNameHash_, tokenAddress));
    }

    /**
     * @notice Computes the ID for an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenId The ID of the interchain token.
     */
    function interchainTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId) {
        tokenId = service.interchainTokenId(TOKEN_FACTORY_DEPLOYER, interchainTokenSalt(chainNameHash, deployer, salt));
    }

    /**
     * @notice Computes the ID for a canonical interchain token based on its address.
     * @param tokenAddress The address of the canonical interchain token.
     * @return tokenId The ID of the canonical interchain token.
     */
    function canonicalInterchainTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = service.interchainTokenId(TOKEN_FACTORY_DEPLOYER, canonicalInterchainTokenSalt(chainNameHash, tokenAddress));
    }

    /**
     * @notice Retrieves the address of an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenAddress The address of the interchain token.
     */
    function interchainTokenAddress(address deployer, bytes32 salt) public view returns (address tokenAddress) {
        tokenAddress = service.interchainTokenAddress(interchainTokenId(deployer, salt));
    }

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @dev Creates a new token and optionally mints an initial amount to a specified minter.
     * @param salt The unique salt for deploying the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals for the token.
     * @param initialSupply The amount of tokens to mint initially (can be zero).
     * @param minter The address to receive the initially minted tokens.
     */
    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply,
        address minter
    ) external payable {
        address sender = msg.sender;
        salt = interchainTokenSalt(chainNameHash, sender, salt);
        bytes memory minterBytes = new bytes(0);

        if (initialSupply > 0) {
            minterBytes = address(this).toBytes();
        } else if (minter != address(0)) {
            minterBytes = minter.toBytes();
        }

        _deployInterchainToken(salt, '', name, symbol, decimals, minterBytes, 0);

        if (initialSupply > 0) {
            bytes32 tokenId = service.interchainTokenId(TOKEN_FACTORY_DEPLOYER, salt);
            IInterchainToken token = IInterchainToken(service.interchainTokenAddress(tokenId));
            ITokenManager tokenManager = ITokenManager(service.tokenManagerAddress(tokenId));

            token.mint(sender, initialSupply);

            token.transferMintership(minter);
            tokenManager.removeFlowLimiter(address(this));

            // If minter == address(0), we still set it as a flow limiter for consistency with the remote token manager.
            tokenManager.addFlowLimiter(minter);

            tokenManager.transferOperatorship(minter);
        }
    }

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param originalChainName The name of the chain where the token originally exists.
     * @param salt The unique salt for deploying the token.
     * @param minter The address to distribute the token on the destination chain.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The amount of gas to send for the deployment.
     */
    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address minter,
        string memory destinationChain,
        uint256 gasValue
    ) external payable {
        string memory tokenName;
        string memory tokenSymbol;
        uint8 tokenDecimals;
        bytes memory minter_ = new bytes(0);

        {
            bytes32 chainNameHash_;
            if (bytes(originalChainName).length == 0) {
                chainNameHash_ = chainNameHash;
            } else {
                chainNameHash_ = keccak256(bytes(originalChainName));
            }

            address sender = msg.sender;
            salt = interchainTokenSalt(chainNameHash_, sender, salt);
            bytes32 tokenId = service.interchainTokenId(TOKEN_FACTORY_DEPLOYER, salt);

            IInterchainToken token = IInterchainToken(service.interchainTokenAddress(tokenId));

            tokenName = token.name();
            tokenSymbol = token.symbol();
            tokenDecimals = token.decimals();

            if (minter != address(0)) {
                if (!token.isMinter(minter)) revert NotMinter(minter);

                minter_ = minter.toBytes();
            }
        }

        _deployInterchainToken(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, minter_, gasValue);
    }

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The number of decimals for the token.
     * @param minter The address to receive the initially minted tokens.
     * @param gasValue The amount of gas to send for the transfer.
     */
    function _deployInterchainToken(
        bytes32 salt,
        string memory destinationChain,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        bytes memory minter,
        uint256 gasValue
    ) internal {
        // slither-disable-next-line arbitrary-send-eth
        service.deployInterchainToken{ value: gasValue }(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, minter, gasValue);
    }

    /**
     * @notice Registers a canonical token as an interchain token and deploys its token manager.
     * @param tokenAddress The address of the canonical token.
     * @return tokenId The unique identifier of the registered interchain token.
     */
    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId) {
        bytes memory params = abi.encode('', tokenAddress);

        if (_isGatewayToken(tokenAddress)) revert GatewayToken(tokenAddress);

        bytes32 salt = canonicalInterchainTokenSalt(chainNameHash, tokenAddress);
        tokenId = service.deployTokenManager(salt, '', TokenManagerType.LOCK_UNLOCK, params, 0);
    }

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
    ) external payable {
        bytes32 salt;
        IInterchainToken token;

        {
            bytes32 chainNameHash_;
            if (bytes(originalChain).length == 0) {
                chainNameHash_ = chainNameHash;
            } else {
                chainNameHash_ = keccak256(bytes(originalChain));
            }
            // This ensures that the token manager has been deployed by this address, so it's safe to trust it.
            salt = canonicalInterchainTokenSalt(chainNameHash_, originalTokenAddress);
            bytes32 tokenId = service.interchainTokenId(TOKEN_FACTORY_DEPLOYER, salt);
            token = IInterchainToken(service.validTokenAddress(tokenId));
        }

        // The 3 lines below will revert if the token does not exist.
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint8 tokenDecimals = token.decimals();

        _deployInterchainToken(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, '', gasValue);
    }

    /**
     * @notice Checks if a given token is a gateway token.
     * @param token The address of the token to check.
     * @return bool True if the token is a gateway token, false otherwise.
     */
    function _isGatewayToken(address token) internal view returns (bool) {
        string memory symbol = IInterchainToken(token).symbol();
        return token == gateway.tokenAddresses(symbol);
    }
}
