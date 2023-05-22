// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManager } from '../interfaces/ITokenManager.sol';

abstract contract TokenManager is ITokenManager {
    address private implementationAddress;

    constructor() {
        implementationAddress = address(this);
    }

    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    function setup(bytes calldata params) external onlyProxy {
        _setup(params);
    }

    // solhint-disable-next-line no-empty-blocks
    function sendToken(string calldata destiantionChain, bytes calldata destinationAddress, uint256 amount) external payable {
        // TODO: implement
    }

    function callContractWithInterchainToken(
        string calldata destiantionChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function giveToken(address destinationAddress, uint256 amount) external returns (uint256) {
        // TODO: implement
    }

    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    function _giveToken(address from, uint256 amount) internal virtual returns (uint256);

    function _setup(bytes calldata params) internal virtual;
}
