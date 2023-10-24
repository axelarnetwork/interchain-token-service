// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
contract ExpressCallHandler is IExpressCallHandler {
    // uint256(keccak256('prefix-express-receive-token'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x88626ceac99c3f34cc516d2581131c4cfb1abd891462d045cfef258326d5b00c;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressCallerSlot(bytes32 commandId, bytes32 payloadHash) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, commandId, payloadHash)));
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _getExpressCaller(bytes32 commandId, bytes32 payloadHash) internal view returns (address expressCaller) {
        uint256 slot = _getExpressCallerSlot(commandId, payloadHash);
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @param expressCaller The address of the express caller
     */
    function _setExpressCaller(bytes32 commandId, bytes32 payloadHash, address expressCaller) internal {
        uint256 slot = _getExpressCallerSlot(commandId, payloadHash);
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }

        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();

        assembly {
            sstore(slot, expressCaller)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param commandId The unique hash for this token transfer
     * @param payloadHash The payload keccak for the receive token
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressCaller(bytes32 commandId, bytes32 payloadHash) internal returns (address expressCaller) {
        uint256 slot = _getExpressCallerSlot(commandId, payloadHash);
        assembly {
            expressCaller := sload(slot)

            if not(iszero(expressCaller)) {
                sstore(slot, 0)
            }
        }
    }
}
