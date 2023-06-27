// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';

import { TokenManagerProxy } from '../proxies/TokenManagerProxy.sol';

/**
 * @title TokenManagerDeployer
 * @notice This contract is used to deploy new instances of the TokenManagerProxy contract.
 */
contract TokenManagerDeployer is ITokenManagerDeployer {
    Create3Deployer public immutable deployer;

    /**
     * @notice Constructor for the TokenManagerDeployer contract
     * @param deployer_ Address of the Create3Deployer contract
     */
    constructor(address deployer_) {
        if (deployer_ == address(0)) revert AddressZero();
        deployer = Create3Deployer(deployer_);
    }

    /**
     * @notice Deploys a new instance of the TokenManagerProxy contract
     * @param tokenId The unique identifier for the token
     * @param implementationType Token manager implementation type
     * @param params Additional parameters used in the setup of the token manager
     */
    function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes calldata params) external payable {
        bytes memory args = abi.encode(address(this), implementationType, tokenId, params);
        bytes memory bytecode = abi.encodePacked(type(TokenManagerProxy).creationCode, args);
        address tokenManagerAddress = deployer.deploy(bytecode, tokenId);
        if (tokenManagerAddress.code.length == 0) revert TokenManagerDeploymentFailed();
    }
}
