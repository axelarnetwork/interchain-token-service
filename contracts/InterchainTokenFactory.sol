// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom, SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

import { IInterchainTokenService } from './interfaces/IInterchainTokenService.sol';
import { IInterchainTokenFactory } from './interfaces/IInterchainTokenFactory.sol';
import { ITokenManagerType } from './interfaces/ITokenManagerType.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IInterchainToken } from './interfaces/IInterchainToken.sol';

contract InterchainTokenFactory is IInterchainTokenFactory, ITokenManagerType, Multicall, Upgradable {
    using AddressBytes for bytes;
    using AddressBytes for address;
    using SafeTokenTransfer for IInterchainToken;
    using SafeTokenTransferFrom for IInterchainToken;
    using SafeTokenCall for IInterchainToken;

    IInterchainTokenService public immutable service;
    bytes32 public immutable chainNameHash;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-factory');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_SALT = keccak256('canonical-token-salt');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('interchain-token-salt');

    constructor(address interchainTokenServiceAddress) {
        if (interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        service = IInterchainTokenService(interchainTokenServiceAddress);
        string memory chainName_ = IInterchainTokenService(interchainTokenServiceAddress).interchainAddressTracker().chainName();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    function interchainTokenSalt(bytes32 chainNameHash_, address deployer, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, chainNameHash_, deployer, salt));
    }

    function canonicalInterchainTokenSalt(bytes32 chainNameHash_, address tokenAddress) public pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_SALT, chainNameHash_, tokenAddress));
    }

    function interchainTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId) {
        tokenId = service.interchainTokenId(address(this), interchainTokenSalt(chainNameHash, deployer, salt));
    }

    function canonicalInterchainTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = service.interchainTokenId(address(this), canonicalInterchainTokenSalt(chainNameHash, tokenAddress));
    }

    function interchainTokenAddress(address deployer, bytes32 salt) public view returns (address tokenAddress) {
        tokenAddress = service.interchainTokenAddress(interchainTokenId(deployer, salt));
    }

    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor,
        address operator
    ) external payable {
        address sender = msg.sender;
        salt = interchainTokenSalt(chainNameHash, sender, salt);
        bytes memory distributorBytes;

        if (mintAmount > 0) {
            distributorBytes = address(this).toBytes();
        } else {
            distributorBytes = distributor.toBytes();
        }

        _deployInterchainToken(salt, '', name, symbol, decimals, distributorBytes, operator.toBytes(), 0);

        if (mintAmount > 0) {
            bytes32 tokenId = service.interchainTokenId(address(this), salt);
            IInterchainToken token = IInterchainToken(service.interchainTokenAddress(tokenId));
            token.mint(address(this), mintAmount);
            token.transferDistributorship(distributor);
        }
    }

    function deployRemoteInterchainToken(
        string calldata originalChainName,
        bytes32 salt,
        address additionalDistributor,
        address optionalOperator,
        string memory destinationChain,
        uint256 gasValue
    ) external payable {
        string memory tokenName;
        string memory tokenSymbol;
        uint8 tokenDecimals;
        bytes memory distributor = new bytes(0);
        bytes memory operator = new bytes(0);

        {
            bytes32 chainNameHash_;
            if (bytes(originalChainName).length == 0) {
                chainNameHash_ = chainNameHash;
            } else {
                chainNameHash_ = keccak256(bytes(originalChainName));
            }
            address sender = msg.sender;
            salt = interchainTokenSalt(chainNameHash_, sender, salt);
            bytes32 tokenId = service.interchainTokenId(address(this), salt);

            IInterchainToken token = IInterchainToken(service.interchainTokenAddress(tokenId));
            ITokenManager tokenManager = ITokenManager(service.tokenManagerAddress(tokenId));

            tokenName = token.name();
            tokenSymbol = token.symbol();
            tokenDecimals = token.decimals();
            if (additionalDistributor != address(0)) {
                if (!token.isDistributor(additionalDistributor)) revert NotDistributor(additionalDistributor);
                distributor = additionalDistributor.toBytes();
            }

            if (optionalOperator != address(0)) {
                if (!tokenManager.isOperator(optionalOperator)) revert NotOperator(optionalOperator);
                operator = optionalOperator.toBytes();
            }
        }

        _deployInterchainToken(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, distributor, operator, gasValue);
    }

    function _deployInterchainToken(
        bytes32 salt,
        string memory destinationChain,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        bytes memory distributor,
        bytes memory operator,
        uint256 gasValue
    ) internal {
        // slither-disable-next-line arbitrary-send-eth
        service.deployInterchainToken{ value: gasValue }(
            salt,
            destinationChain,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            distributor,
            operator,
            gasValue
        );
    }

    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId) {
        bytes memory params = abi.encode('', tokenAddress);
        bytes32 salt = canonicalInterchainTokenSalt(chainNameHash, tokenAddress);
        tokenId = service.deployTokenManager(salt, '', TokenManagerType.LOCK_UNLOCK, params, 0);
    }

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
            bytes32 tokenId = service.interchainTokenId(address(this), salt);
            token = IInterchainToken(service.tokenAddress(tokenId));
        }

        // The 3 lines below will revert if the token does not exist.
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint8 tokenDecimals = token.decimals();

        _deployInterchainToken(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, '', '', gasValue);
    }

    function interchainTransfer(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        uint256 gasValue
    ) external payable {
        if (bytes(destinationChain).length == 0) {
            address tokenAddress = service.interchainTokenAddress(tokenId);
            IInterchainToken token = IInterchainToken(tokenAddress);
            token.safeTransfer(destinationAddress.toAddress(), amount);
        } else {
            // slither-disable-next-line arbitrary-send-eth
            service.interchainTransfer{ value: gasValue }(tokenId, destinationChain, destinationAddress, amount, new bytes(0));
        }
    }

    function tokenTransferFrom(bytes32 tokenId, uint256 amount) external payable {
        address tokenAddress = service.tokenAddress(tokenId);
        IInterchainToken token = IInterchainToken(tokenAddress);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function tokenApprove(bytes32 tokenId, uint256 amount) external payable {
        address tokenAddress = service.tokenAddress(tokenId);
        IInterchainToken token = IInterchainToken(tokenAddress);
        address tokenManager = service.tokenManagerAddress(tokenId);

        token.safeCall(abi.encodeWithSelector(token.approve.selector, tokenManager, amount));
    }
}
