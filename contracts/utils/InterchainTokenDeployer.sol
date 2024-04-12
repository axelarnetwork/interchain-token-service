// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Create3Fixed } from './Create3Fixed.sol';

import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';
import { IInterchainToken } from '../interfaces/IInterchainToken.sol';

/**
 * @title InterchainTokenDeployer
 * @notice This contract is used to deploy new instances of the InterchainTokenProxy contract.
 */
contract InterchainTokenDeployer is IInterchainTokenDeployer, Create3Fixed {
    address public immutable implementationAddress;

    /**
     * @notice Constructor for the InterchainTokenDeployer contract.
     * @param implementationAddress_ Address of the InterchainToken contract.
     */
    constructor(address implementationAddress_) {
        if (implementationAddress_ == address(0)) revert AddressZero();

        implementationAddress = implementationAddress_;
    }

    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract.
     * @param salt The salt used by Create3Deployer.
     * @param tokenId TokenId for the token.
     * @param minter Address of the minter.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @return tokenAddress Address of the deployed token.
     */
    function deployInterchainToken(
        bytes32 salt,
        bytes32 tokenId,
        address minter,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (address tokenAddress) {
        // Use a minimal proxy for cheap token deployment and auto-verification on explorers
        // https://eips.ethereum.org/EIPS/eip-1167
        // The minimal proxy bytecode is the same as https://github.com/OpenZeppelin/openzeppelin-contracts/blob/94697be8a3f0dfcd95dfb13ffbd39b5973f5c65d/contracts/proxy/Clones.sol#L28
        // The minimal proxy bytecode is 0x37 = 55 bytes long
        bytes memory bytecode = new bytes(0x37);
        address implementation = implementationAddress;

        /// @solidity memory-safe-assembly
        assembly {
            // The first 0x20 = 32 bytes (0x00 - 0x19) are reserved for the length.
            // The next 0x14 = 20 bytes (0x20 - 0x33) are the ones below.
            mstore(add(bytecode, 0x20), shl(0x60, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73))
            // The next 0x14 = 20 bytes (0x34 - 0x47) are the implementation address.
            mstore(add(bytecode, 0x34), shl(0x60, implementation))
            // The last 0x0f = 15 bytes (0x48 - 0x56) are the ones below.
            mstore(add(bytecode, 0x48), shl(0x88, 0x5af43d82803e903d91602b57fd5bf3))
        }

        tokenAddress = _create3(bytecode, salt);
        if (tokenAddress.code.length == 0) revert TokenDeploymentFailed();

        IInterchainToken(tokenAddress).init(tokenId, minter, name, symbol, decimals);
    }

    /**
     * @notice Returns the interchain token deployment address.
     * @param salt The deployment salt.
     * @return tokenAddress The token address.
     */
    function deployedAddress(bytes32 salt) external view returns (address tokenAddress) {
        return _create3Address(salt);
    }
}
