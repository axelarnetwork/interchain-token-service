// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

abstract contract TokenManager is ITokenManager {
    address private immutable implementationAddress;
    IInterchainTokenService public immutable interchainTokenService;

    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenService(interchainTokenService_);
        implementationAddress = address(this);
    }

    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    function setup(bytes calldata params) external onlyProxy {
        _setup(params);
    }

    function sendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable virtual {
        _takeToken(msg.sender, amount);
        _transmitSendToken(destinationChain, destinationAddress, amount);
    }

    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable virtual {
        _takeToken(msg.sender, amount);
        _transmitSendTokenWithData(destinationChain, destinationAddress, amount, data);
    }

    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        return _giveToken(destinationAddress, amount);
    }

    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    function _transmitSendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) internal virtual {
        interchainTokenService.transmitSendToken{ value: msg.value }(
            _getTokenId(),
            msg.sender,
            destinationChain,
            destinationAddress,
            amount
        );
    }

    function _transmitSendTokenWithData(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        interchainTokenService.transmitSendTokenWithData{ value: msg.value }(
            _getTokenId(),
            msg.sender,
            destinationChain,
            destinationAddress,
            amount,
            data
        );
    }

    function _setup(bytes calldata params) internal virtual;

    function _getTokenId() internal view returns (bytes32 tokenId) {
        tokenId = ITokenManagerProxy(address(this)).tokenId();
    }
}
