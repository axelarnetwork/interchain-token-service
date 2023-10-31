// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeTokenTransfer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { IStandardizedTokenRegistrar } from '../interfaces/IStandardizedTokenRegistrar.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IStandardizedToken } from '../interfaces/IStandardizedToken.sol';

import { Multicall } from '../utils/Multicall.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';

contract StandardizedTokenRegistrar is IStandardizedTokenRegistrar, ITokenManagerType, Multicall, Upgradable {
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;
    using SafeTokenTransfer for IStandardizedToken;

    IInterchainTokenService public immutable service;
    bytes32 public immutable chainNameHash;

    bytes32 private constant CONTRACT_ID = keccak256('standardized-token-registrar');

    struct DeployParams {
        address deployer;
        bytes distributor;
        bytes operator;
    }

    mapping(bytes32 => DeployParams) public deploymentParameterMap;

    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_SALT = keccak256('standardized-token-salt');

    constructor(address interchainTokenServiceAddress) {
        if (interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        service = IInterchainTokenService(interchainTokenServiceAddress);
        string memory chainName_ = IInterchainTokenService(interchainTokenServiceAddress).remoteAddressValidator().chainName();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    function getStandardizedTokenSalt(address deployer, bytes32 salt) public view returns (bytes32) {
        return keccak256(abi.encode(PREFIX_STANDARDIZED_TOKEN_SALT, chainNameHash, deployer, salt));
    }

    function getStandardizedTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId) {
        tokenId = service.getCustomTokenId(address(this), getStandardizedTokenSalt(deployer, salt));
    }

    function getStandardizedTokenAddress(address deployer, bytes32 salt) public view returns (address tokenAddress) {
        tokenAddress = service.getStandardizedTokenAddress(getStandardizedTokenId(deployer, salt));
    }

    function deployStandardizedToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address distributor
    ) external payable {
        address sender = msg.sender;
        salt = getStandardizedTokenSalt(sender, salt);
        bytes32 tokenId = service.getCustomTokenId(address(this), salt);

        service.deployAndRegisterStandardizedToken(salt, name, symbol, decimals, mintAmount, distributor);
        ITokenManager tokenManager = ITokenManager(service.getTokenManagerAddress(tokenId));
        tokenManager.transferOperatorship(sender);

        IStandardizedToken token = IStandardizedToken(service.getStandardizedTokenAddress(tokenId));
        token.safeTransfer(sender, mintAmount);
    }

    function deployRemoteStandarizedToken(
        bytes32 salt,
        address additionalDistributor,
        address optionalOperator,
        uint256 mintAmount,
        string memory destinationChain,
        uint256 gasValue
    ) external payable {
        string memory tokenName;
        string memory tokenSymbol;
        uint8 tokenDecimals;
        bytes memory distributor;
        bytes memory operator;

        {
            address sender = msg.sender;
            salt = getStandardizedTokenSalt(sender, salt);
            bytes32 tokenId = service.getCustomTokenId(address(this), salt);

            IStandardizedToken token = IStandardizedToken(service.getStandardizedTokenAddress(tokenId));
            ITokenManager tokenManager = ITokenManager(service.getTokenManagerAddress(tokenId));

            tokenName = token.name();
            tokenSymbol = token.symbol();
            tokenDecimals = token.decimals();
            if (additionalDistributor != address(0)) {
                if (!token.isDistributor(additionalDistributor)) revert NotDistributor(additionalDistributor);
                distributor = additionalDistributor.toBytes();
            } else if (mintAmount != 0) {
                revert NonZeroMintAmount();
            }
            if (optionalOperator != address(0)) {
                if (!tokenManager.isOperator(optionalOperator)) revert NotOperator(optionalOperator);
                operator = optionalOperator.toBytes();
            }
        }

        _deployAndRegisterRemoteStandardizedToken(
            salt,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            distributor,
            operator,
            mintAmount,
            destinationChain,
            gasValue
        );
    }

    function _deployAndRegisterRemoteStandardizedToken(
        bytes32 salt,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        bytes memory distributor,
        bytes memory operator,
        uint256 mintAmount,
        string memory destinationChain,
        uint256 gasValue
    ) internal {
        // slither-disable-next-line arbitrary-send-eth
        service.deployAndRegisterRemoteStandardizedToken{ value: gasValue }(
            salt,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            distributor,
            '',
            mintAmount,
            operator,
            destinationChain,
            gasValue
        );
    }
}
