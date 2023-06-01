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

    // solhint-disable-next-line no-empty-blocks
    function sendToken(string calldata destiantionChain, bytes calldata destinationAddress, uint256 amount) external payable {
        // TODO: implement
    }

    function callContractWithInterchainToken(
        string calldata destiantionChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        return _giveToken(destinationAddress, amount);
    }

    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    function _setup(bytes calldata params) internal virtual;

    function _getTokenId() internal view returns (bytes32 tokenId) {
        tokenId = ITokenManagerProxy(address(this)).tokenId();
    }
}
