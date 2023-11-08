// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3.sol';

import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';
import { IInterchainToken } from '../interfaces/IInterchainToken.sol';

import { InterchainTokenProxy } from '../proxies/InterchainTokenProxy.sol';

/**
 * @title InterchainTokenDeployer
 * @notice This contract is used to deploy new instances of the InterchainTokenProxy contract.
 */
contract InterchainTokenDeployer is IInterchainTokenDeployer, Create3 {
    address public immutable implementationAddress;

    /**
     * @notice Constructor for the InterchainTokenDeployer contract
     * @param implementationAddress_ Address of the InterchainToken contract
     */
    constructor(address implementationAddress_) {
        if (implementationAddress_ == address(0)) revert AddressZero();
        implementationAddress = implementationAddress_;
    }

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract
     * @param salt The salt used by Create3Deployer
     * @param tokenManager Address of the token manager
     * @param distributor Address of the distributor
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param decimals Decimals of the token
     * @return tokenAddress Address of the deployed token
     */
    // slither-disable-next-line locked-ether
    function deployInterchainToken(
        bytes32 salt,
        address tokenManager,
        address distributor,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external payable returns (address tokenAddress) {
        // slither-disable-next-line too-many-digits
        bytes memory bytecode = new bytes(0x37); //bytes.concat(type(InterchainTokenProxy).creationCode, abi.encode(implementationAddress, params));
        address implementation = implementationAddress;
        assembly {
            mstore(add(bytecode, 0x20), shl(0x60, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73))
            mstore(add(bytecode, 0x34), shl(0x60, implementation))
            mstore(add(bytecode, 0x48), shl(0x88, 0x5af43d82803e903d91602b57fd5bf3))
        }
        tokenAddress = _create3(bytecode, salt);
        if (tokenAddress.code.length == 0) revert TokenDeploymentFailed();

        IInterchainToken(tokenAddress).init(tokenManager, distributor, name, symbol, decimals);
    }

    function deployedAddress(bytes32 salt) external view returns (address tokenAddress) {
        return _create3Address(salt);
    }
}
