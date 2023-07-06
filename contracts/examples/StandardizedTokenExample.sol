// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { PreExistingERC20 } from './PreExistingERC20.sol';

// This will deploy standardized tokens everywhere with mint/burn token managers, and will have an initial supploy
contract StandardizedTokenExample {
    IInterchainTokenService public immutable service;

    constructor(address service_) {
        service = IInterchainTokenService(service_);
    }

    function deployAndRegisterStandardizedToken(bytes32 salt, string calldata name, string calldata symbol, uint8 decimals, uint256 initialSupply) external {
        bytes32 tokenId = service.getCustomTokenId(address(this), salt);
        address tokenManager = service.getTokenManagerAddress(tokenId);
        service.deployAndRegisterStandardizedToken(salt, name, symbol, decimals, initialSupply, tokenManager);
    }


    function deployAndRegisterRemoteStandardizedToken(bytes32 salt, string calldata name, string calldata symbol, uint8 decimals, string calldata destinationChain) external payable {
        service.deployAndRegisterRemoteStandardizedToken(salt, name, symbol, decimals, '', '', destinationChain, msg.value);
    }

    // You could combine the above using multicall but this would probably be done by a frontend, in solidity you would just sequence the above calls.
    function doBoth(bytes32 salt, string calldata name, string calldata symbol, uint8 decimals, uint256 initialSupply, string[] calldata destinationChains, uint256[] calldata gasValues) external payable {
        bytes32 tokenId = service.getCustomTokenId(address(this), salt);
        address tokenManager = service.getTokenManagerAddress(tokenId);
        uint256 length = destinationChains.length;
        if(gasValues.length != length) revert ('LengthMissmatch');
        bytes[] memory data = new bytes[](length+1);
        data[1] = abi.encodeWithSelector(IInterchainTokenService.deployAndRegisterStandardizedToken.selector, salt, name, symbol, decimals, initialSupply, tokenManager);
        for(uint256 i; i < length; ++i) {
            data[i+1] = abi.encodeWithSelector(IInterchainTokenService.deployAndRegisterRemoteStandardizedToken.selector, salt, name, symbol, decimals, '', '', destinationChains[i], gasValues[i]);
        }
        service.multicall{value: msg.value}(data);
    }
}