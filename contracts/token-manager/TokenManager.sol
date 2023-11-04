// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';
import { Implementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Implementation.sol';

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';

import { Operatable } from '../utils/Operatable.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';

/**
 * @title The main functionality of TokenManagers.
 * @notice This contract is responsible for handling tokens before initiating a cross chain token transfer, or after receiving one.
 */
abstract contract TokenManager is ITokenManager, Operatable, FlowLimit, Implementation {
    using AddressBytes for bytes;

    IInterchainTokenService public immutable interchainTokenService;

    bytes32 private constant CONTRACT_ID = keccak256('token-manager');

    // uint256(keccak256('token-address')) - 1
    uint256 internal constant TOKEN_ADDRESS_SLOT = 0xc4e632779a6a7838736dd7e5e6a0eadf171dd37dfb6230720e265576dfcf42ba;

    /**
     * @notice Constructs the TokenManager contract.
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
        if (msg.sender != address(interchainTokenService)) revert NotService(msg.sender);
        _;
    }

    /**
     * @dev A modifier that allows only the token to execute the function.
     */
    modifier onlyToken() {
        if (msg.sender != tokenAddress()) revert NotToken(msg.sender);
        _;
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure override returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @dev Reads the stored token address from the predetermined storage slot
     * @return tokenAddress_ The address of the token
     */
    function tokenAddress() public view virtual returns (address tokenAddress_) {
        assembly {
            tokenAddress_ := sload(TOKEN_ADDRESS_SLOT)
        }
    }

    /**
     * @notice A function that returns the token id.
     * @dev This will only work when implementation is called by a proxy, which stores the tokenId as an immutable.
     */
    function interchainTokenId() public view returns (bytes32) {
        // slither-disable-next-line var-read-using-this
        return this.interchainTokenId();
    }

    /**
     * @dev This function should only be called by the proxy, and only once from the proxy constructor
     * @param params the parameters to be used to initialize the TokenManager. The exact format depends
     * on the type of TokenManager used but the first 32 bytes are reserved for the address of the operator,
     * stored as bytes (to be compatible with non-EVM chains)
     */
    function setup(bytes calldata params) external override(Implementation, IImplementation) onlyProxy {
        bytes memory operatorBytes = abi.decode(params, (bytes));
        address operator;

        /**
         * @dev Specifying an empty operator will default to the service being the operator. This makes it easy to deploy
         * remote interchain tokens without knowing anything about the service address at the destination.
         */
        if (operatorBytes.length == 0) {
            operator = address(interchainTokenService);
        } else {
            operator = operatorBytes.toAddress();

            // Add flow limiter role to the service by default. The operator can remove this if they so choose.
            _addAccountRoles(address(interchainTokenService), 1 << uint8(Roles.FLOW_LIMITER));
        }

        _addAccountRoles(operator, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));

        _setup(params);
    }

    /**
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param metadata any additional data to be sent with the transfer.
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

        interchainTokenService.transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice Calls the service to initiate a cross-chain transfer with data after taking the appropriate amount of tokens from the user.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param data the data to pass to the destination contract.
     */
    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable virtual {
        address sender = msg.sender;

        amount = _takeToken(sender, amount);

        // rate limit the outgoing amount to destination
        _addFlowOut(amount);

        uint32 version = 0;
        interchainTokenService.transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            abi.encodePacked(version, data)
        );
    }

    /**
     * @notice Calls the service to initiate a cross-chain transfer after taking the appropriate amount of tokens from the user. This can only be called by the token itself.
     * @param sender the address of the user paying for the cross chain transfer.
     * @param destinationChain the name of the chain to send tokens to.
     * @param destinationAddress the address of the user to send tokens to.
     * @param amount the amount of tokens to take from msg.sender.
     * @param metadata any additional data to be sent with the transfer
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

        interchainTokenService.transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            destinationAddress,
            amount,
            metadata
        );
    }

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param destinationAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will only be different than `amount` in cases where the token takes some on-transfer fee.
     */
    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        // rate limit the incoming amount from source
        _addFlowIn(amount);
        amount = _giveToken(destinationAddress, amount);
        return amount;
    }

    /**
     * @notice This function gives token to a specified address. Can only be called by the service.
     * @param sourceAddress the address to give tokens to.
     * @param amount the amount of token to give.
     * @return the amount of token actually given, which will onle be differen than `amount` in cases where the token takes some on-transfer fee.
     */
    function takeToken(address sourceAddress, uint256 amount) external onlyService returns (uint256) {
        amount = _takeToken(sourceAddress, amount);
        // rate limit the outgoing amount to destination
        _addFlowOut(amount);
        return amount;
    }

    /**
     * @notice This function adds a flow limiter for this TokenManager. Can only be called by the operator.
     * @param flowLimiter the address of the new flow limiter.
     */
    function addFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        if (flowLimiter == address(0)) revert ZeroAddress();

        _addRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function removes a flow limiter for this TokenManager. Can only be called by the operator.
     * @param flowLimiter the address of an existing flow limiter.
     */
    function removeFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        if (flowLimiter == address(0)) revert ZeroAddress();

        _removeRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function sets the flow limit for this TokenManager. Can only be called by the flow limiters.
     * @param flowLimit_ the maximum difference between the tokens flowing in and/or out at any given interval of time (6h)
     */
    function setFlowLimit(uint256 flowLimit_) external onlyRole(uint8(Roles.FLOW_LIMITER)) {
        _setFlowLimit(flowLimit_, interchainTokenId());
    }

    /**
     * @dev Stores the token address in the predetermined storage slot
     * @param tokenAddress_ The address of the token to store
     */
    function _setTokenAddress(address tokenAddress_) internal {
        assembly {
            sstore(TOKEN_ADDRESS_SLOT, tokenAddress_)
        }
    }

    /**
     * @notice Transfers tokens from a specific address to this contract.
     * Must be overridden in the inheriting contract.
     * @param from The address from which the tokens will be sent
     * @param amount The amount of tokens to receive
     * @return uint amount of tokens received
     */
    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Transfers tokens from this contract to a specific address.
     * Must be overridden in the inheriting contract.
     * @param receiver The address to which the tokens will be sent
     * @param amount The amount of tokens to send
     * @return uint amount of tokens sent
     */
    function _giveToken(address receiver, uint256 amount) internal virtual returns (uint256);

    /**
     * @dev Additional setup logic to perform
     * Must be overridden in the inheriting contract.
     * @param params The setup parameters
     */
    function _setup(bytes calldata params) internal virtual;
}
