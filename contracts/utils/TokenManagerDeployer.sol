// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';

import { TokenManagerProxy } from '../proxies/TokenManagerProxy.sol';

contract TokenManagerDeployer is ITokenManagerDeployer {
    Create3Deployer public immutable deployer;

    constructor(address deployer_) {
        if (deployer_ == address(0)) revert AddressZero();
        deployer = Create3Deployer(deployer_);
    }

    function deployTokenManager(
        bytes32 tokenId,
        TokenManagerType implementationType,
        bytes calldata params
    ) external payable {
        bytes memory args = abi.encode(address(this), implementationType, tokenId, params);
        bytes memory bytecode = abi.encodePacked(type(TokenManagerProxy).creationCode, args);
        address tokenManagerAddress = deployer.deploy(bytecode, tokenId);
        if (tokenManagerAddress.code.length == 0) revert TokenManagerDeploymentFailed();
    }
}
