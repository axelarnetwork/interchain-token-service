// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

import { Adminable } from '../utils/Adminable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';

abstract contract TokenManager is ITokenManager, Adminable, FlowLimit {
    using AddressBytesUtils for bytes;

    address private immutable implementationAddress;
    IInterchainTokenService public immutable interchainTokenService;

    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenService(interchainTokenService_);
        implementationAddress = address(this);
    }

    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    modifier onlyToken() {
        if (msg.sender != tokenAddress()) revert NotToken();
        _;
    }

    function tokenAddress() public view virtual returns (address);

    function setup(bytes calldata params) external onlyProxy {
        bytes memory adminBytes = abi.decode(params, (bytes));
        address admin_;
        // Specifying an empty admin will default to the service being the admin. This makes it easy to deploy remote canonical tokens without knowing anything about the service address at the destination.
        if (adminBytes.length == 0) {
            admin_ = address(interchainTokenService);
        } else {
            admin_ = adminBytes.toAddress();
        }
        _setAdmin(admin_);
        _setup(params);
    }

    function sendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendToken(sender, destinationChain, destinationAddress, amount);
    }

    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendTokenWithData(sender, destinationChain, destinationAddress, amount, data);
    }

    function sendSelf(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable virtual onlyToken {
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendToken(sender, destinationChain, destinationAddress, amount);
    }

    function callContractWithSelf(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable virtual onlyToken {
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendTokenWithData(sender, destinationChain, destinationAddress, amount, data);
    }

    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _giveToken(destinationAddress, amount);
        _addFlowIn(amount);
        return amount;
    }

    function setFlowLimit(uint256 flowLimit) external onlyAdmin {
        _setFlowLimit(flowLimit);
    }

    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    function _transmitSendToken(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) internal virtual {
        interchainTokenService.transmitSendToken{ value: msg.value }(_getTokenId(), sender, destinationChain, destinationAddress, amount);
    }

    function _transmitSendTokenWithData(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        interchainTokenService.transmitSendTokenWithData{ value: msg.value }(
            _getTokenId(),
            sender,
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
