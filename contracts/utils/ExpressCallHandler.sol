// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
contract ExpressCallHandler is IExpressCallHandler {
    // uint256(keccak256('prefix-express-give-token'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af865619;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param payload the payload of the receive token
     * @param commandId The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressReceiveTokenSlot(bytes calldata payload, bytes32 commandId) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, payload, commandId)));
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param payload The payload for the receive token
     * @param commandId The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressReceiveToken(bytes calldata payload, bytes32 commandId, address expressCaller) internal {
        uint256 slot = _getExpressReceiveTokenSlot(payload, commandId);
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }
        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressReceive(payload, commandId, expressCaller);
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param payload The payload for the receive token
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveToken(bytes calldata payload, bytes32 commandId) public view returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(payload, commandId);
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param payload the payload for the receive token
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressReceiveToken(bytes calldata payload, bytes32 commandId) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(payload, commandId);
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionFulfilled(payload, commandId, expressCaller);
        }
    }
}
