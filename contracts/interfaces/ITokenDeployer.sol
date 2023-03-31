// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

interface ITokenDeployer {
    function deployer() external view returns (Create3Deployer);

    function bytecodeServer() external view returns (address);

    function tokenImplementation() external view returns (address);

    function thisAddress() external view returns (ITokenDeployer);

    function deployToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        bytes32 salt
    ) external payable returns (address tokenAddress);

    function getDeploymentAddress(address deployerAddress, bytes32 salt) external view returns (address deployment);

    function getBytecode(bytes calldata args) external view returns (bytes memory bytecode);
}
