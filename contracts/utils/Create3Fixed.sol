// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDeploy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeploy.sol';
import { ContractAddress } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/ContractAddress.sol';
import { CreateDeploy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/CreateDeploy.sol';
import { Create3Address } from './Create3Address.sol';

/**
 * @title Create3 contract
 * @notice This contract can be used to deploy a contract with a deterministic address that depends only on
 * the deployer address and deployment salt, not the contract bytecode and constructor parameters.
 */
contract Create3Fixed is Create3Address, IDeploy {
    using ContractAddress for address;

    bytes internal constant createDeployBytecode = hex'608060405234801561001057600080fd5b50610162806100206000396000f3fe60806040526004361061001d5760003560e01c806277436014610022575b600080fd5b61003561003036600461007b565b610037565b005b8051602082016000f061004957600080fd5b50565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b60006020828403121561008d57600080fd5b813567ffffffffffffffff808211156100a557600080fd5b818401915084601f8301126100b957600080fd5b8135818111156100cb576100cb61004c565b604051601f8201601f19908116603f011681019083821181831017156100f3576100f361004c565b8160405282815287602084870101111561010c57600080fd5b82602086016020830137600092810160200192909252509594505050505056fea264697066735822122094780ce55d28f1d568f4e0ab1b9dc230b96e952b73d2e06456fbff2289fa27f464736f6c63430008150033';

    constructor() Create3Address(keccak256(createDeployBytecode)) {}
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
        bytes memory createDeployBytecode_ = createDeployBytecode;
        uint256 length = createDeployBytecode_.length;
        assembly {
            createDeploy := create2(0, add(createDeployBytecode_, 0x20), length, deploySalt)
        }

        if (address(createDeploy) == address(0)) revert DeployFailed();
        // Deploy using create
        createDeploy.deploy(bytecode);
    }
}
