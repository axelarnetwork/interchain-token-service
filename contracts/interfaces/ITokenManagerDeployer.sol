// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

interface ITokenManagerDeployer {
    error AddressZero();
    error TokenManagerDeploymentFailed();

    function deployer() external view returns (Create3Deployer);

    function deployTokenManager(bytes32 tokenId, uint256 tokenManagerType, bytes calldata params) external payable;
}
