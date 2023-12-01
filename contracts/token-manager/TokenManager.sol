// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';
import { Implementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Implementation.sol';

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';

import { Operatable } from '../utils/Operatable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';

/**
 * @title TokenManager
 * @notice This contract is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
abstract contract TokenManager is ITokenManager, ITokenManagerType, Operatable, FlowLimit, Implementation {
    using AddressBytes for bytes;

    IInterchainTokenService public immutable interchainTokenService;

    bytes32 private constant CONTRACT_ID = keccak256('token-manager');

    /**
     * @dev Latest version of metadata that's supported.
     */
    uint32 private constant LATEST_METADATA_VERSION = 0;

    /**
     * @notice Constructs the TokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service.
     */
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();

        interchainTokenService = IInterchainTokenService(interchainTokenService_);
    }

    /**
     * @notice A modifier that allows only the interchain token service to execute the function.
     */
    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService(msg.sender);
        _;
    }

    /**
     * @notice A modifier that allows only the token to execute the function.
     */
    modifier onlyToken() {
        if (msg.sender != this.tokenAddress()) revert NotToken(msg.sender);
        _;
    }

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id.
     */
    function contractId() external pure override returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Reads the token address from the proxy.
     * @dev This function is not supported when directly called on the implementation. It
     * must be called by the proxy.
     * @return tokenAddress_ The address of the token.
     */
    function tokenAddress() external view virtual returns (address) {
        revert NotSupported();
    }

    /**
     * @notice A function that returns the token id.
     * @dev This will only work when implementation is called by a proxy, which stores the tokenId as an immutable.
     * @return bytes32 The interchain token ID.
     */
    function interchainTokenId() public pure returns (bytes32) {
        revert NotSupported();
    }

    /**
     * @notice A function that should return the token address from the setup params.
     * @param params The setup parameters.
     * @return tokenAddress_ The token address.
     */
    function getTokenAddressFromParams(bytes calldata params) external pure returns (address tokenAddress_) {
        (, tokenAddress_) = abi.decode(params, (bytes, address));
    }

    /**
     * @notice Setup function for the TokenManager.
     * @dev This function should only be called by the proxy, and only once from the proxy constructor.
     * The exact format of params depends on the type of TokenManager used but the first 32 bytes are reserved
     * for the address of the operator, stored as bytes (to be compatible with non-EVM chains)
     * @param params The parameters to be used to initialize the TokenManager.
     */
    function setup(bytes calldata params) external override(Implementation, IImplementation) onlyProxy {
        bytes memory operatorBytes = abi.decode(params, (bytes));

        address operator;
        if (operatorBytes.length != 0) {
            operator = operatorBytes.toAddress();
        }

        // If an operator is not provided, set `address(0)` as the operator.
        // This allows anyone to easily check if a custom operator was set on the token manager.
        _addAccountRoles(operator, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));

        // Add flow limiter role to the service by default. The operator can remove this if they so choose.
        _addAccountRoles(address(interchainTokenService), (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));

        _setup(params);
    }

    /**
     * @notice Calls the service to initiate an interchain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The address on the destination chain to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param metadata Any additional data to be sent with the transfer.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable virtual {
        address sender = msg.sender;

        amount = _takeToken(sender, amount);

        // rate limit the outgoing amount to destination
        _addFlowOut(amount);

        // slither-disable-next-line var-read-using-this
        interchainTokenService.transmitInterchainTransfer{ value: msg.value }(
            this.interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice Calls the service to initiate an interchain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The address on the destination chain to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param data The data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes memory data
    ) external payable virtual {
        address sender = msg.sender;

        amount = _takeToken(sender, amount);

        // rate limit the outgoing amount to destination
        _addFlowOut(amount);

        // slither-disable-next-line var-read-using-this
        interchainTokenService.transmitInterchainTransferWithData{ value: msg.value }(
            this.interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            LATEST_METADATA_VERSION,
            data
        );
    }

    /**
     * @notice Calls the service to initiate an interchain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender The address of the sender paying for the interchain transfer.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress  The address on the destination chain to send tokens to.
     * @param amount The amount of tokens to take from msg.sender.
     * @param metadata Any additional data to be sent with the transfer.
     */
    function transmitInterchainTransfer(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable virtual onlyToken {
        amount = _takeToken(sender, amount);

        // rate limit the outgoing amount to destination
        _addFlowOut(amount);

        // slither-disable-next-line var-read-using-this
        interchainTokenService.transmitInterchainTransfer{ value: msg.value }(
            this.interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param destinationAddress The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        // rate limit the incoming amount from source
        _addFlowIn(amount);

        amount = _giveToken(destinationAddress, amount);

        return amount;
    }

    /**
     * @notice This function gives token to a specified address.
     * @dev Can only be called by the service.
     * @param sourceAddress The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(address sourceAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _takeToken(sourceAddress, amount);

        // rate limit the outgoing amount to destination
        _addFlowOut(amount);

        return amount;
    }

    /**
     * @notice This function adds a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of the new flow limiter.
     */
    function addFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        if (flowLimiter == address(0)) revert ZeroAddress();

        _addRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function removes a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of an existing flow limiter.
     */
    function removeFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        if (flowLimiter == address(0)) revert ZeroAddress();

        _removeRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice Query if an address is a flow limiter.
     * @param addr The address to query for.
     * @return bool Boolean value representing whether or not the address is a flow limiter.
     */
    function isFlowLimiter(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function sets the flow limit for this TokenManager.
     * @dev Can only be called by the flow limiters.
     * @param flowLimit_ The maximum difference between the tokens flowing in and/or out at any given interval of time (6h).
     */
    function setFlowLimit(uint256 flowLimit_) external onlyRole(uint8(Roles.FLOW_LIMITER)) {
        // slither-disable-next-line var-read-using-this
        _setFlowLimit(flowLimit_, this.interchainTokenId());
    }

    /**
     * @notice Transfers tokens from a specific address to this contract.
     * @dev Must be overridden in the inheriting contract.
     * @param from The address from which the tokens will be sent.
     * @param amount The amount of tokens to receive.
     * @return uint256 The amount of tokens received.
     */
    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Transfers tokens from this contract to a specific address.
     * @dev Must be overridden in the inheriting contract.
     * @param receiver The address to which the tokens will be sent.
     * @param amount The amount of tokens to send.
     * @return uint256 The amount of tokens sent.
     */
    function _giveToken(address receiver, uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Additional setup logic to perform
     * @dev Must be overridden in the inheriting contract.
     * @param params The setup parameters.
     */
    function _setup(bytes calldata params) internal virtual {}
}
