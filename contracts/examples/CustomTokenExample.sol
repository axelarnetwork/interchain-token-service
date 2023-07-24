// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { CustomERC20 } from './CustomERC20.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';

// This will deploy standardized tokens everywhere with mint/burn token managers, and will have an initial supploy
contract CustomTokenExample is ITokenManagerType {
    using AddressBytesUtils for address;

    address public immutable tokenAddress;
    IInterchainTokenService public immutable service;

    constructor(string memory name, string memory symbol, uint8 decimals, address service_, uint256 tokenCap) {
        service = IInterchainTokenService(service_);
        tokenAddress = address(new CustomERC20(name, symbol, decimals, address(this), tokenCap));
    }

    function deployTokenManager(bytes32 salt) external {
        bytes memory params = service.getParamsMintBurn(address(this).toBytes(), tokenAddress);
        bytes32 tokenId = service.deployCustomTokenManager(salt, TokenManagerType.MINT_BURN, params);
        address tokenManager = service.getTokenManagerAddress(tokenId);
        CustomERC20(tokenAddress).transferDistributorship(tokenManager);
    }
}