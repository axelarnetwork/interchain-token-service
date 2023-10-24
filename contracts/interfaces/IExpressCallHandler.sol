// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExpressCallHandler {
    error AlreadyExpressCalled();
    error SameDestinationAsCaller();
}
