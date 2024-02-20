// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDeploy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeploy.sol';
import { ContractAddress } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/ContractAddress.sol';
import { CreateDeploy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/CreateDeploy.sol';
import { Create3AddressFixed } from './Create3AddressFixed.sol';

/**
 * @title Create3Fixed contract
 * @notice This contract can be used to deploy a contract with a deterministic address that depends only on
 * the deployer address and deployment salt, not the contract bytecode and constructor parameters. 
 * It uses a fixed bytecode to allow changing the compilation settings without affecting the deployment address in the future.
 */
contract Create3Fixed is Create3AddressFixed, IDeploy {
    using ContractAddress for address;

    /**
     * @notice Deploys a new contract using the `CREATE3` method.
     * @dev This function first deploys the CreateDeploy contract using
     * the `CREATE2` opcode and then utilizes the CreateDeploy to deploy the
     * new contract with the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt to influence the contract address
     * @return deployed The address of the deployed contract
     */
    function _create3(bytes memory bytecode, bytes32 deploySalt) internal returns (address deployed) {
        deployed = _create3Address(deploySalt);

        if (bytecode.length == 0) revert EmptyBytecode();
        if (deployed.isContract()) revert AlreadyDeployed();

        // Deploy using create2
        CreateDeploy createDeploy;
        bytes memory createDeployBytecode_ = CREATE_DEPLOY_BYTECODE;
        uint256 length = createDeployBytecode_.length;
        assembly {
            createDeploy := create2(0, add(createDeployBytecode_, 0x20), length, deploySalt)
        }

        if (address(createDeploy) == address(0)) revert DeployFailed();
        // Deploy using create
        createDeploy.deploy(bytecode);
    }
}
