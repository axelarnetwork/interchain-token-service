// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

import { Adminable } from '../utils/Adminable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { Implementation } from '../utils/Implementation.sol';

/// @title The main functionality of TokenManagers. 
/// @author Foivos Antoulinakis
/// @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
abstract contract TokenManager is ITokenManager, Adminable, FlowLimit, Implementation {
    using AddressBytesUtils for bytes;

    IInterchainTokenService public immutable interchainTokenService;

    /// @param interchainTokenService_ The address of the interchain token service, which can be stored in an immutable variable saving some gas.
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenService(interchainTokenService_);
    }

    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    modifier onlyToken() {
        if (msg.sender != tokenAddress()) revert NotToken();
        _;
    }

    function tokenAddress() public view virtual returns (address);

    /// @dev This is supposed to only be hidden by the proxy and only be called once from the proxy constructor
    /// @param params the parameters to be used to initialize the TokenManager. The exact format depends on the type of TokenManager used but the first 32 bytes are reserved for the address of the admin, stored as bytes (to be compatible with non-EVM chains)
    function setup(bytes calldata params) external override onlyProxy {
        bytes memory adminBytes = abi.decode(params, (bytes));
        address admin_;
        // Specifying an empty admin will default to the service being the admin. This makes it easy to deploy remote standardized tokens without knowing anything about the service address at the destination.
        if (adminBytes.length == 0) {
            admin_ = address(interchainTokenService);
        } else {
            admin_ = adminBytes.toAddress();
        }
        _setAdmin(admin_);
        _setup(params);
    }

    /// @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the address of the user to send tokens to.
    /// @param amount the amount of tokens to take from msg.sender.
    function sendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendToken(sender, destinationChain, destinationAddress, amount);
    }

    /// @notice Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the address of the user to send tokens to.
    /// @param amount the amount of tokens to take from msg.sender.
    /// @param data the data to pass to the destination contract.
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

    /// @notice Calls the service to initiate the a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
    /// @param sender the address of the user paying for the cross chain transfer.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the address of the user to send tokens to.
    /// @param amount the amount of tokens to take from msg.sender.
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

    /// @notice Calls the service to initiate the a cross-chain transfer with data after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
    /// @param sender the address of the user paying for the cross chain transfer.
    /// @param destinationChain the name of the chain to send tokens to.
    /// @param destinationAddress the address of the user to send tokens to.
    /// @param amount the amount of tokens to take from msg.sender.
    /// @param data the data to pass to the destination contract.
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

    /// @notice This function gives token to a specified address. Can only be called by the service.
    /// @param destinationAddress the address to give tokens to.
    /// @param amount the amount of token to give.
    /// @return the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _giveToken(destinationAddress, amount);
        _addFlowIn(amount);
        return amount;
    }

    /// @notice This function sets the flow limit for this TokenManager. Can only be called by the admin.
    /// @param flowLimit the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
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
