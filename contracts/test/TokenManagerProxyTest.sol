// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManagerProxy } from '../proxies/TokenManagerProxy.sol';

contract TokenManagerProxyTest is TokenManagerProxy {
    constructor(
        address interchainTokenService_,
        uint256 implementationType_,
        bytes32 tokenId,
        bytes memory params
    ) TokenManagerProxy(interchainTokenService_, implementationType_, tokenId, params) {}

    function getContractId() external pure returns (bytes32) {
        return contractId();
    }
}
