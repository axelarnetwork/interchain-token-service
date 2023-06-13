// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManagerType } from './ITokenManagerType.sol';
import { IAdminable } from './IAdminable.sol';

interface ITokenManager is ITokenManagerType, IAdminable {
    error TokenLinkerZeroAddress();
    error NotService();
    error TakeTokenFailed();
    error GiveTokenFailed();
    error NotProxy();

    function tokenAddress() external view returns (address);

    function sendToken(string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable;

    function callContractWithInterchainToken(
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function giveToken(address destinationAddress, uint256 amount) external returns (uint256);
}
