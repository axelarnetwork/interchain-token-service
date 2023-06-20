// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { IStandardizedTokenDeployer } from '../interfaces/IStandardizedTokenDeployer.sol';

import { StandardizedTokenProxy } from '../proxies/StandardizedTokenProxy.sol';

contract StandardizedTokenDeployer is IStandardizedTokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable implementationMintBurnAddress;
    address public immutable implementationLockUnlockAddress;

    constructor(address deployer_, address implementationLockUnlockAddress_, address implementationMintBurnAddress_) {
        if (deployer_ == address(0) || implementationLockUnlockAddress_ == address(0) || implementationMintBurnAddress_ == address(0))
            revert AddressZero();
        deployer = Create3Deployer(deployer_);
        implementationLockUnlockAddress = implementationLockUnlockAddress_;
        implementationMintBurnAddress = implementationMintBurnAddress_;
    }

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
        address implementationAddress = distributor == tokenManager ? implementationMintBurnAddress : implementationLockUnlockAddress;
        {
            bytes memory params = abi.encode(tokenManager, distributor, name, symbol, decimals, mintAmount, mintTo);
            bytecode = abi.encodePacked(type(StandardizedTokenProxy).creationCode, abi.encode(implementationAddress, params));
        }
        address tokenAddress = deployer.deploy(bytecode, salt);
        if (tokenAddress.code.length == 0) revert TokenDeploymentFailed();
    }
}
