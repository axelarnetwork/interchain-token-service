// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

contract TokenDeployer is ITokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable bytecodeServer;

    constructor(address deployer_, address bytecodeServer_) {
        deployer = Create3Deployer(deployer_);
        bytecodeServer = bytecodeServer_;
    }

    function _getBytecode() internal view returns (bytes memory bytecode) {
        bytecode = bytecodeServer.code;
    }

    function deployToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        bytes32 salt
    ) external payable returns (address tokenAddress) {
        bytes memory bytecode = _getBytecode();
        tokenAddress = deployer.deployAndInit(
            bytecode,
            salt,
            abi.encodeWithSelector(IERC20BurnableMintable.setup.selector, abi.encode(name, symbol, decimals, owner))
        );
    }
}
