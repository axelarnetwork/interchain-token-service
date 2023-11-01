// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IExpressCallHandler Interface
 * @dev Interface with functions used to integrate the interchain token service with the GMP express service
 * by providing methods to handle express calls for token transfers and token transfers with contract calls between chains.
 */
interface IExpressCallHandler {
    error AlreadyExpressCalled();
    error SameDestinationAsCaller();

    event ExpressReceive(bytes payload, bytes32 indexed sendHash, address indexed expressCaller);
    event ExpressExecutionFulfilled(bytes payload, bytes32 indexed sendHash, address indexed expressCaller);

    /**
     * @notice Gets the address of the express caller for a specific token transfer.
     * @param payload The payload for the receive token.
     * @param commandId The unique hash for this token transfer.
     * @return expressCaller The address of the express caller for this token transfer.
     */
    function getExpressReceiveToken(bytes calldata payload, bytes32 commandId) external view returns (address expressCaller);
}
