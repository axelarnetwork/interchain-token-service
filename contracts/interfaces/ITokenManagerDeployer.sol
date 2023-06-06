// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

interface ITokenManagerDeployer is ITokenManagerType {
    error AddressZero();
    error TokenManagerDeploymentFailed();

    event TokenManagerDeployed(bytes32 indexed tokenId, TokenManagerType indexed tokenManagerType, bytes params);

    function deployer() external view returns (Create3Deployer);

    function bytecodeServer() external view returns (address);

    function getTokenManagerAddress(bytes32 tokenId) external view returns (address deployment);
}
