// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { Create3Deployer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol';

import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';

contract TokenDeployer is ITokenDeployer {
    Create3Deployer public immutable deployer;
    address public immutable bytecodeServer;
    address public immutable tokenImplementation;
    ITokenDeployer public immutable thisAddress;

    constructor(address deployer_, address bytecodeServer_, address tokenImplementation_) {
        deployer = Create3Deployer(deployer_);
        bytecodeServer = bytecodeServer_;
        tokenImplementation = tokenImplementation_;
        thisAddress = ITokenDeployer(this);
    }

    // this function assumes that the sender will delegatecall to deploy tokens, which is the case.
    function getDeploymentAddress(address deployerAddress, bytes32 salt) external view returns (address deployment) {
        deployment = deployer.deployedAddress(deployerAddress, salt);
    }

    function getBytecode(bytes calldata args) external view returns (bytes memory bytecode) {
        uint256 bytecodeLen;
        address server = bytecodeServer;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bytecodeLen := extcodesize(server)
        }
        uint256 argsLen = args.length;
        uint256 totalLen = argsLen + bytecodeLen;
        bytecode = new bytes(totalLen);
        uint256 start = bytecodeLen + 32;
        // solhint-disable-next-line no-inline-assembly
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
        // convert args to calldata by doing an external call to handle more easily in the function
        bytes memory bytecode = thisAddress.getBytecode(args);
        tokenAddress = deployer.deploy(bytecode, salt);
    }
}
