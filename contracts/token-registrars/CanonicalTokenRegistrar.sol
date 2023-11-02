// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ICanonicalTokenRegistrar } from '../interfaces/ICanonicalTokenRegistrar.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';

contract CanonicalTokenRegistrar is ICanonicalTokenRegistrar, ITokenManagerType, Multicall, Upgradable {
    using SafeTokenTransferFrom for IERC20;

    IInterchainTokenService public immutable service;
    bytes32 public immutable chainNameHash;

    bytes32 internal constant PREFIX_CANONICAL_TOKEN_SALT = keccak256('canonical-token-salt');
    bytes32 private constant CONTRACT_ID = keccak256('canonical-token-registrar');

    constructor(address interchainTokenService) {
        if (interchainTokenService == address(0)) revert ZeroAddress();
        service = IInterchainTokenService(interchainTokenService);
        string memory chainName_ = IInterchainTokenService(interchainTokenService).interchainAddressTracker().chainName();
        chainNameHash = keccak256(bytes(chainName_));
    }

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    function canonicalTokenSalt(address tokenAddress) public view returns (bytes32 salt) {
        salt = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_SALT, chainNameHash, tokenAddress));
    }

    function canonicalTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = service.tokenId(address(this), canonicalTokenSalt(tokenAddress));
    }

    function registerCanonicalToken(address tokenAddress) external payable returns (bytes32 tokenId) {
        bytes memory params = abi.encode('', tokenAddress);
        bytes32 salt = canonicalTokenSalt(tokenAddress);
        tokenId = service.deployTokenManager(salt, '', TokenManagerType.LOCK_UNLOCK, params, 0);
    }

    function deployAndRegisterRemoteCanonicalToken(bytes32 salt, string calldata destinationChain, uint256 gasValue) external payable {
        // This ensures that the token manager has been deployed by this address, so it's safe to trust it.
        bytes32 tokenId = service.tokenId(address(this), salt);
        IERC20Named token = IERC20Named(service.tokenAddress(tokenId));
        // The 3 lines below will revert if the token manager does not exist.
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();
        uint8 tokenDecimals = token.decimals();

        // slither-disable-next-line arbitrary-send-eth
        service.deployInterchainToken{ value: gasValue }(
            salt,
            destinationChain,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            '',
            gasValue
        );
    }

    function transferCanonicalToken(
        address tokenAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        uint256 gasValue
    ) external payable {
        // This ensures that the token manager has been deployed by this address, so it's safe to trust it.
        bytes32 tokenId = canonicalTokenId(tokenAddress);
        // slither-disable-next-line unused-return
        service.validTokenManagerAddress(tokenId);
        IERC20 token = IERC20(tokenAddress);

        token.safeTransferFrom(msg.sender, address(this), amount);

        address tokenManagerAddress = service.tokenManagerAddress(tokenId);
        if (!token.approve(tokenManagerAddress, amount)) revert ApproveFailed();

        // slither-disable-next-line arbitrary-send-eth
        service.interchainTransfer{ value: gasValue }(tokenId, destinationChain, destinationAddress, amount, bytes(''));
    }
}
