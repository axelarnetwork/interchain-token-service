// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExpressCallHandler {
    error AlreadyExpressCalled(address prevExpressCaller);

    event ExpressReceive(bytes payload, bytes32 indexed sendHash, address indexed expressCaller);
    event ExpressExecutionFulfilled(bytes payload, bytes32 indexed sendHash, address indexed expressCaller);

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param payload the payload for the receive token
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveToken(bytes calldata payload, bytes32 commandId) external view returns (address expressCaller);
}
