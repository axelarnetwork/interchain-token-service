// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { IStandardizedTokenRegistrar } from '../interfaces/IStandardizedTokenRegistrar.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IStandardizedToken } from '../interfaces/IStandardizedToken.sol';

import { Multicall } from '../utils/Multicall.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';

contract StandardizedTokenRegistrar is IStandardizedTokenRegistrar, ITokenManagerType, Multicall {
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;

    IInterchainTokenService public immutable service;
    string public chainName;
    bytes32 public immutable chainNameHash;

    struct DeployParams {
        address deployer;
        bytes distributor;
        bytes operator;
    }

    mapping(bytes32 => DeployParams) public deploymentParameterMap;

    bytes32 internal constant PREFIX_STANDARDIZED_TOKEN_SALT = keccak256('standardized-token-salt');

    constructor(address interchainTokenServiceAddress, string memory chainName_) {
        if (interchainTokenServiceAddress == address(0)) revert ZeroAddress();
        service = IInterchainTokenService(interchainTokenServiceAddress);
        chainName = chainName_;
        chainNameHash = keccak256(bytes(chainName_));
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
        token.transfer(sender, mintAmount);
    }

    function deployRemoteStandarizedToken(
        bytes32 salt,
        bool sameDistributor,
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
            if (sameDistributor) distributor = token.distributor().toBytes();
            operator = tokenManager.operator().toBytes();
        }

        _deployAndRegisterRemoteStandardizedToken(
            salt,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            distributor,
            operator,
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
        string memory destinationChain,
        uint256 gasValue
    ) internal {
        service.deployAndRegisterRemoteStandardizedToken{ value: gasValue }(
            salt,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            distributor,
            '',
            0,
            operator,
            destinationChain,
            gasValue
        );
    }
}
