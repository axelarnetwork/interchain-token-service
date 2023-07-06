// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { PreExistingERC20 } from './PreExistingERC20.sol';

contract PreExistingTokenExample {
    address public immutable tokenAddress;
    IInterchainTokenService public immutable service;
    bytes32 public tokenId;

    constructor(string memory name, string memory symbol, uint8 decimals, address service_) {
        tokenAddress = address(new PreExistingERC20(name, symbol, decimals));
        service = IInterchainTokenService(service_);
    }

    function registerToken() external {
        tokenId = service.registerCanonicalToken(tokenAddress);
    }

    function deployRemoteToken(string calldata destinationChain) external payable {
        service.deployRemoteCanonicalToken(tokenId, destinationChain, msg.value);
    }

    // You could combine the above using multicall but this would probably be done by a frontend, in solidity you would just sequence the above calls.
    function registerTokenAndDeployRemoteTokens(string[] calldata destinationChains, uint256[] calldata gasValues) external payable {
        bytes32 tokenId_ = service.getCanonicalTokenId(tokenAddress);
        tokenId = tokenId_;
        uint256 length = destinationChains.length;
        if(gasValues.length != length) revert ('LengthMissmatch');
        bytes[] memory data = new bytes[](length+1);
        data[1] = abi.encodeWithSelector(IInterchainTokenService.registerCanonicalToken.selector, tokenAddress);
        for(uint256 i; i < length; ++i) {
            data[i+1] = abi.encodeWithSelector(IInterchainTokenService.deployRemoteCanonicalToken.selector, destinationChains[i], gasValues[i]);
        }
        service.multicall{value: msg.value}(data);
    }
}