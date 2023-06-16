// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenManagerProxy } from '../interfaces/ITokenManagerProxy.sol';

import { Adminable } from '../utils/Adminable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { Implementation } from '../utils/Implementation.sol';

/**
 * @title TokenManager
 * @dev An abstract contract that manages tokens for other contracts.
 * It includes functions for sending and receiving tokens.
 * It is inherited by other contracts that implement specific token manager logic. There are
 * currently 3 types of token manager contracts that inherit this contract.
 */
abstract contract TokenManager is ITokenManager, Adminable, FlowLimit, Implementation {
    using AddressBytesUtils for bytes;

    IInterchainTokenService public immutable interchainTokenService;

    /**
     * @dev Constructs the TokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service
     */
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenService(interchainTokenService_);
    }

    /**
     * @dev A modifier that allows only the interchain token service to execute the function.
     */
    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    /**
     * @dev A modifier that allows only the token to execute the function.
     */
    modifier onlyToken() {
        if (msg.sender != tokenAddress()) revert NotToken();
        _;
    }

    /**
     * @dev A function that should return the address of the token.
     * Must be overridden in the inheriting contract.
     * @return address address of the token.
     */
    function tokenAddress() public view virtual returns (address);

    /**
     * @dev A setup function that can only be called by the proxy.
     * @param params Initialization parameters
     */
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

    /**
     * @dev A function to send tokens to a specific address on another chain
     * @param destinationChain The chain to which the tokens should be sent
     * @param destinationAddress The address on the destination chain to which the tokens should be sent
     * @param amount The amount of tokens to send
     */
    function sendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable virtual {
        address sender = msg.sender;
        amount = _takeToken(sender, amount);
        _addFlowOut(amount);
        _transmitSendToken(sender, destinationChain, destinationAddress, amount);
    }

    /**
     * @dev A function to send tokens to and call a specific funtion on a contract on another chain.
     * @param destinationChain The chain where the contract is located
     * @param destinationAddress The address of the contract to call
     * @param amount The amount of tokens to send
     * @param data The data specifying which function to call and what arguments to pass in
     */
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

    /**
     * @dev Sends tokens to an address on behalf of a sender address.
     * @param sender The original sender of the tokens
     * @param destinationChain The chain to which the tokens should be sent
     * @param destinationAddress The address on the destination chain to which the tokens should be sent
     * @param amount The amount of tokens to send
     */
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

    /**
     * @dev Calls and sends tokens to a contract on behalf of a sender address.
     * @param sender The original sender of the tokens
     * @param destinationChain The chain where the contract is located
     * @param destinationAddress The address of the contract to call
     * @param amount The amount of tokens to send with the call
     * @param data The data specifying which function to call and what arguments to pass in
     */
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

    /**
     * @dev Gives tokens to an address, only callable by the interchain token service.
     * @param destinationAddress The address to which tokens will be sent
     * @param amount The amount of tokens to send
     * @return uint The amount of tokens sent
     */
    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _giveToken(destinationAddress, amount);
        _addFlowIn(amount);
        return amount;
    }

    /**
     * @dev Sets the flow limit, only callable by the admin.
     * @param flowLimit The new flow limit
     */
    function setFlowLimit(uint256 flowLimit) external onlyAdmin {
        _setFlowLimit(flowLimit);
    }

    /**
     * @dev Transfers tokens from a specific address to this contract.
     * Must be overridden in the inheriting contract.
     * @param from The address from which the tokens will be sent
     * @param amount The amount of tokens to receive
     * @return uint amount of tokens received
     */
    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @dev Transfers tokens from this contract to a specific address.
     * Must be overridden in the inheriting contract.
     * @param from The address to which the tokens will be sent
     * @param amount The amount of tokens to send
     * @return uint amount of tokens sent
     */
    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @dev Calls the interchain token service to send tokens to an address on another chain
     * @param sender The sender of the tokens
     * @param destinationChain The chain to which the tokens will be sent
     * @param destinationAddress The address on the destination chain where the tokens will be sent
     * @param amount The amount of tokens to send
     */
    function _transmitSendToken(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) internal virtual {
        interchainTokenService.transmitSendToken{ value: msg.value }(_getTokenId(), sender, destinationChain, destinationAddress, amount);
    }

    /**
     * @dev Calls the interchain token service to send tokens to and call a function on a contract on another chain
     * @param sender The sender of the tokens
     * @param destinationChain The chain to which the tokens will be sent
     * @param destinationAddress The address on the destination chain where the tokens will be sent
     * @param amount The amount of tokens to send
     * @param data The data needed to call the contract on the destination chain
     */
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

    /**
     * @dev Additional setup logic to perform
     * Must be overridden in the inheriting contract.
     * @param params The setup parameters
     */
    function _setup(bytes calldata params) internal virtual;

    /**
     * @dev Gets the token ID from the token manager proxy.
     * @return tokenId The ID of the token
     */
    function _getTokenId() internal view returns (bytes32 tokenId) {
        tokenId = ITokenManagerProxy(address(this)).tokenId();
    }
}
