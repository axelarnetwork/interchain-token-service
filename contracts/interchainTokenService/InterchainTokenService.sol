// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { TokenManagerDeployer } from '../utils/TokenManagerDeployer.sol';

contract InterchainTokenService is IInterchainTokenService, TokenManagerDeployer, AxelarExecutable {
    address public immutable implementationLockUnlock;
    address public immutable implementationMintBurn;
    address public immutable implementationCanonical;
    address public immutable implementationGateway;

    constructor(
        address deployer_,
        address bytecodeServer_,
        address gateway_,
        address[] memory tokenManagerImplementations
    ) TokenManagerDeployer(deployer_, bytecodeServer_) AxelarExecutable(gateway_) {
        if (tokenManagerImplementations.length != 4) revert LengthMismatch();
        if (tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)] == address(0)) revert TokenServiceZeroAddress();
        implementationLockUnlock = tokenManagerImplementations[uint256(TokenManagerType.LOCK_UNLOCK)];
        if (tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)] == address(0)) revert TokenServiceZeroAddress();
        implementationMintBurn = tokenManagerImplementations[uint256(TokenManagerType.MINT_BURN)];
        if (tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)] == address(0)) revert TokenServiceZeroAddress();
        implementationCanonical = tokenManagerImplementations[uint256(TokenManagerType.CANONICAL)];
        if (tokenManagerImplementations[uint256(TokenManagerType.GATEWAY)] == address(0)) revert TokenServiceZeroAddress();
        implementationGateway = tokenManagerImplementations[uint256(TokenManagerType.GATEWAY)];
    }

    modifier onlyRemoteService

    // solhint-disable-next-line no-empty-blocks
    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId) {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function getCustomTokenId(address admin, bytes32 salt) external view returns (bytes32 tokenId) {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function registerCanonicalToken(address tokenAddress) external returns (bytes32 tokenId) {
        // TODO: implement
    }

    function registerCanonicalTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable returns (bytes32 tokenId) {
        // TODO: implement
    }

    function deployRemoteCanonicalTokens(
        bytes32 tokenId,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function registerCustomToken(bytes32 salt, TokenManagerType tokenManagerType, bytes calldata params) external {
        // TODO: implement
    }

    function registerRemoteCustomTokens(
        bytes32 salt,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata params,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external payable {
        // TODO: implement
    }

    function registerCustomTokenAndDeployRemote(
        bytes32 salt,
        TokenManagerType tokenManagerType,
        bytes calldata params,
        string[] calldata destinationChains,
        TokenManagerType[] calldata tokenManagerTypes,
        bytes[] calldata remoteParams,
        uint256[] calldata gasValues // solhint-disable-next-line no-empty-blocks
    ) external {
        // TODO: implement
    }

    // solhint-disable-next-line no-empty-blocks
    function getImplementation(TokenManagerType tokenManagerType) external view returns (address tokenManagerAddress) {
        if (tokenManagerType == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (tokenManagerType == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (tokenManagerType == TokenManagerType.CANONICAL) {
            return implementationCanonical;
        } else if (tokenManagerType == TokenManagerType.GATEWAY) {
            return implementationGateway;
        }
    }

    function _execute(string calldata sourceChain, string calldata sourceAddress, bytes calldata payload) internal override {

    }
}
