// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';
import { ITokenLinkerType } from '../interfaces/ITokenLinkerType.sol';

interface ITokenLinkerDeployer is ITokenLinkerType {
    error AddressZero();
    error TokenLinkerDeploymentFailed();

    function deployer() external view returns (Create3Deployer);

    function bytecodeServer() external view returns (address);

    function getTokenLinkerAddress(bytes32 tokenLinkerId) external view returns (address tokenLinkerAddress);
}
