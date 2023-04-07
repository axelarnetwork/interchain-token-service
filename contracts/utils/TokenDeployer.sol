// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';

contract TokenDeployer is ITokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable bytecodeServer;
    address public tokenImplementation;

    constructor(address deployer_, address bytecodeServer_, address tokenImplementation_) {
        deployer = Create3Deployer(deployer_);
        bytecodeServer = bytecodeServer_;
        tokenImplementation = tokenImplementation_;
    }

    function getBytecode(bytes calldata args) external view returns (bytes memory bytecode) {
        uint256 bytecodeLen;
        address server = bytecodeServer;
        assembly {
            bytecodeLen := extcodesize(server)
        }
        uint256 argsLen = args.length;
        uint256 totalLen = argsLen + bytecodeLen;
        bytecode = new bytes(totalLen);
        uint256 start = bytecodeLen + 32;
        assembly {
            extcodecopy(server, add(bytecode, 32), 0, bytecodeLen)
            calldatacopy(add(bytecode, start), args.offset, argsLen)
            mstore(bytecode, totalLen)
        }
    }

    function deployToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        bytes32 salt
    ) external payable returns (address tokenAddress) {
        bytes memory args = abi.encode(tokenImplementation, name, symbol, decimals, owner);
        // convert args to calldata to handle more easily in the function
        bytes memory bytecode = this.getBytecode(args);
        tokenAddress = deployer.deploy(bytecode, salt);
    }
}
