// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';

import { StandardizedTokenProxy } from '../proxies/StandardizedTokenProxy.sol';

/**
 * @title StandardizedTokenDeployer
 * @notice This contract is used to deploy new instances of the StandardizedTokenProxy contract.
 */
contract StandardizedTokenDeployer is IStandardizedTokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable implementationAddress;

    /**
     * @notice Constructor for the StandardizedTokenDeployer contract
     * @param deployer_ Address of the Create3Deployer contract
     * @param implementationAddress_ Address of the StandardizedToken contract
     */
    constructor(address deployer_, address implementationAddress_) {
        if (deployer_ == address(0) || implementationAddress_ == address(0))
            revert AddressZero();
        deployer = Create3Deployer(deployer_);
        implementationAddress = implementationAddress_;
    }

    /**
     * @notice Deploys a new instance of the StandardizedTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @param mintAmount Amount of tokens to mint initially
     * @param mintTo Address to mint initial tokens to
     */
    function deployStandardizedToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 mintAmount,
        address mintTo
    ) external payable {
        bytes memory bytecode;
        {
            bytes memory params = abi.encode(tokenManager, distributor, name, symbol, decimals, mintAmount, mintTo);
            bytecode = abi.encodePacked(type(StandardizedTokenProxy).creationCode, abi.encode(implementationAddress, params));
        }
        address tokenAddress = deployer.deploy(bytecode, salt);
        if (tokenAddress.code.length == 0) revert TokenDeploymentFailed();
    }
}
