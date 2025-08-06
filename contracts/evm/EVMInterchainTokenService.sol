// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AbstractInterchainTokenService } from '../abstract/AbstractInterchainTokenService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { Create3AddressFixed } from '../utils/Create3AddressFixed.sol';

/**
 * @title EVM Interchain Token Service
 * @notice EVM-specific implementation of the Interchain Token Service
 * @dev Implements standard EVM token operations with deterministic addresses
 */
contract EVMInterchainTokenService is AbstractInterchainTokenService {
    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        string memory itsHubAddress_,
        address tokenManagerImplementation_,
        address tokenHandler_
    )
        AbstractInterchainTokenService(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            gasService_,
            interchainTokenFactory_,
            chainName_,
            itsHubAddress_,
            tokenManagerImplementation_,
            tokenHandler_
        )
    {}

    // ============ EVM-Specific Implementations ============

    /**
     * @notice Deploy interchain token using CREATE3 for deterministic addresses
     */
    function _deployInterchainToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address owner,
        bytes memory operator
    ) internal virtual override returns (address tokenAddress) {
        bytes32 salt = keccak256(abi.encodePacked(PREFIX_INTERCHAIN_TOKEN_SALT, tokenId));
        
        tokenAddress = _create3Deploy(
            salt,
            abi.encodeWithSelector(
                IInterchainTokenDeployer.deployInterchainToken.selector,
                name,
                symbol,
                decimals,
                initialSupply,
                owner,
                operator
            )
        );
    }

    /**
     * @notice Get token address using deterministic CREATE3 derivation
     */
    function _getTokenAddress(bytes32 tokenId) internal view virtual override returns (address tokenAddress) {
        bytes32 salt = keccak256(abi.encodePacked(PREFIX_INTERCHAIN_TOKEN_SALT, tokenId));
        return _create3Address(salt, type(IInterchainTokenDeployer).creationCode);
    }

    /**
     * @notice EVM token creation has no additional cost beyond gas
     */
    function _getTokenCreationPrice() internal view virtual override returns (uint256 price) {
        return 0; // No additional cost for EVM token creation
    }

    /**
     * @notice Standard ERC20 transfer
     */
    function _transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal virtual override returns (bool success) {
        return IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @notice Standard ERC20 minting (if supported)
     */
    function _mintToken(
        address token,
        address to,
        uint256 amount
    ) internal virtual override returns (bool success) {
        // Try to call mint function if it exists
        (success, ) = token.call(abi.encodeWithSignature("mint(address,uint256)", to, amount));
    }

    /**
     * @notice Standard ERC20 burning (if supported)
     */
    function _burnToken(
        address token,
        address from,
        uint256 amount
    ) internal virtual override returns (bool success) {
        // Try to call burnFrom function if it exists
        (success, ) = token.call(abi.encodeWithSignature("burnFrom(address,uint256)", from, amount));
    }

    // ============ EVM-Specific Public Functions ============

    /**
     * @notice Get deterministic token address for EVM
     */
    function interchainTokenAddress(bytes32 tokenId) public view returns (address tokenAddress) {
        return _getTokenAddress(tokenId);
    }

    /**
     * @notice Transmit interchain transfer (EVM-specific)
     */
    function transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        _transmitInterchainTransfer(tokenId, sourceAddress, destinationChain, destinationAddress, amount, metadata, msg.value);
    }
} 