// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
abstract contract ExpressCallHandler is IExpressCallHandler {
    // uint256(keccak256('prefix-express-receive-token'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x88626ceac99c3f34cc516d2581131c4cfb1abd891462d045cfef258326d5b00c;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @return slot The calculated slot for this token transfer
     */
    function _expressExecuteSlot(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, commandId, sourceChain, sourceAddress, payloadHash));
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressExecutor The address of the express caller for this token transfer
     */
    function _getExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal view returns (address expressExecutor) {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);

        assembly {
            expressExecutor := sload(slot)
        }
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @param expressExecutor The address of the express caller
     */
    function _setExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        address expressExecutor
    ) internal {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);
        address currentExecutor;

        assembly {
            currentExecutor := sload(slot)
        }

        if (currentExecutor != address(0)) revert AlreadyExpressCalled();

        assembly {
            sstore(slot, expressExecutor)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @return expressExecutor The address of the express caller for this token transfer
     */
    function _popExpressExecutor(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) internal returns (address expressExecutor) {
        bytes32 slot = _expressExecuteSlot(commandId, sourceChain, sourceAddress, payloadHash);

        assembly {
            expressExecutor := sload(slot)
            if expressExecutor {
                sstore(slot, 0)
            }
        }
    }
}
