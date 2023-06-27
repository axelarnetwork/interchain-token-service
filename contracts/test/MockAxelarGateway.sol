// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMockAxelarGateway } from '../interfaces/IMockAxelarGateway.sol';

contract MockAxelarGateway is IMockAxelarGateway {
    mapping(bytes32 => address) private _addressStorage;
    mapping(bytes32 => bool) private _boolStorage;

    bytes32 internal constant PREFIX_COMMAND_EXECUTED = keccak256('command-executed');
    bytes32 internal constant PREFIX_TOKEN_ADDRESS = keccak256('token-address');
    bytes32 internal constant PREFIX_TOKEN_TYPE = keccak256('token-type');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED = keccak256('contract-call-approved');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT = keccak256('contract-call-approved-with-mint');

    /******************\
    |* Public Methods *|
    \******************/

    function callContract(string calldata destinationChain, string calldata destinationContractAddress, bytes calldata payload) external {
        emit ContractCall(msg.sender, destinationChain, destinationContractAddress, keccak256(payload), payload);
    }

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view override returns (bool) {
        return _boolStorage[_getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash)];
    }

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external override returns (bool valid) {
        bytes32 key = _getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, msg.sender, payloadHash);
        valid = _boolStorage[key];
        if (valid) _boolStorage[key] = false;
    }

    /***********\
    |* Getters *|
    \***********/

    function isCommandExecuted(bytes32 commandId) public view override returns (bool) {
        return _boolStorage[_getIsCommandExecutedKey(commandId)];
    }

    function tokenAddresses(string calldata symbol) external view returns (address tokenAddress) {
        tokenAddress = _addressStorage[_getTokenAddressKey(symbol)];
    }

    /********************\
    |* Setter Functions *|
    \********************/

    function approveContractCall(bytes calldata params, bytes32 commandId) external {
        (
            string memory sourceChain,
            string memory sourceAddress,
            address contractAddress,
            bytes32 payloadHash,
            bytes32 sourceTxHash,
            uint256 sourceEventIndex
        ) = abi.decode(params, (string, string, address, bytes32, bytes32, uint256));

        _setContractCallApproved(commandId, sourceChain, sourceAddress, contractAddress, payloadHash);
        emit ContractCallApproved(commandId, sourceChain, sourceAddress, contractAddress, payloadHash, sourceTxHash, sourceEventIndex);
    }

    function setTokenAddress(string calldata symbol, address tokenAddress) external {
        _addressStorage[_getTokenAddressKey(symbol)] = tokenAddress;
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getIsCommandExecutedKey(bytes32 commandId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_COMMAND_EXECUTED, commandId));
    }

    function _getIsContractCallApprovedKey(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_CONTRACT_CALL_APPROVED, commandId, sourceChain, sourceAddress, contractAddress, payloadHash));
    }

    function _getTokenAddressKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_ADDRESS, symbol));
    }

    /********************\
    |* Internal Setters *|
    \********************/

    function _setCommandExecuted(bytes32 commandId, bool executed) internal {
        _boolStorage[_getIsCommandExecutedKey(commandId)] = executed;
    }

    function _setContractCallApproved(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal {
        _boolStorage[_getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash)] = true;
    }
}
