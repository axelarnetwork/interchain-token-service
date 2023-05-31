// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { TokenManagerDeployer } from '../utils/TokenManagerDeployer.sol';

contract InterchainTokenService is IInterchainTokenService, TokenManagerDeployer {
    // This calculates the token manager address for a given ID even if that token manager is not yet deployed.
    // solhint-disable-next-line no-empty-blocks
    constructor(address deployer_, address bytecodeServer_) TokenManagerDeployer(deployer_, bytecodeServer_) {}

    // solhint-disable-next-line no-empty-blocks
    function getValidTokenManagerAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        // TODO: implement
    }

    // There are two ways to cacluate a tokenId, one is for pre-existing tokens, and anyone can do this for a token once.
    // solhint-disable-next-line no-empty-blocks
    function getCanonicalTokenId(address tokenAddress) external view returns (bytes32 tokenId) {
        // TODO: implement
    }

    // The other is by providing a salt, and your address (msg.sender) is used for the calculation.
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
}
