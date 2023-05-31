// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenManager {
    function sendToken(string calldata destiantionChain, bytes calldata destinationAddress, uint256 amount) external payable;

    function callContractWithInterchainToken(
        string calldata destiantionChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);
}
