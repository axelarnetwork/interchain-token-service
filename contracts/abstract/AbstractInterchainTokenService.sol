// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { ExpressExecutorTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/express/ExpressExecutorTracker.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Pausable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Pausable.sol';
import { InterchainAddressTracker } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/InterchainAddressTracker.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenHandler } from '../interfaces/ITokenHandler.sol';
import { ITokenManagerDeployer } from '../interfaces/ITokenManagerDeployer.sol';
import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IInterchainTokenExpressExecutable } from '../interfaces/IInterchainTokenExpressExecutable.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { IMinter } from '../interfaces/IMinter.sol';
import { Create3AddressFixed } from '../utils/Create3AddressFixed.sol';
import { Operator } from '../utils/Operator.sol';
import { ChainTracker } from '../utils/ChainTracker.sol';
import { ItsHubAddressTracker } from '../utils/ItsHubAddressTracker.sol';

/**
 * @title Abstract Interchain Token Service
 * @notice Abstract base contract for Interchain Token Service with virtual functions for chain-specific implementations
 * @dev This contract provides the core ITS functionality while allowing chain-specific overrides
 */
abstract contract AbstractInterchainTokenService is
    Upgradable,
    Operator,
    Pausable,
    Multicall,
    Create3AddressFixed,
    ExpressExecutorTracker,
    InterchainAddressTracker,
    ChainTracker,
    ItsHubAddressTracker,
    IInterchainTokenService
{
    using AddressBytes for bytes;
    using AddressBytes for address;

    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;
    address public immutable interchainTokenFactory;
    bytes32 public immutable chainNameHash;

    address public immutable interchainTokenDeployer;
    address public immutable tokenManagerDeployer;

    address public immutable tokenManager;
    address public immutable tokenHandler;

    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_ID = keccak256('its-interchain-token-id');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('its-interchain-token-salt');

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-service');
    bytes32 private constant EXECUTE_SUCCESS = keccak256('its-execute-success');
    bytes32 private constant EXPRESS_EXECUTE_SUCCESS = keccak256('its-express-execute-success');

    uint256 private constant MESSAGE_TYPE_INTERCHAIN_TRANSFER = 0;
    uint256 private constant MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 1;
    uint256 private constant MESSAGE_TYPE_SEND_TO_HUB = 3;
    uint256 private constant MESSAGE_TYPE_RECEIVE_FROM_HUB = 4;
    uint256 private constant MESSAGE_TYPE_LINK_TOKEN = 5;
    uint256 private constant MESSAGE_TYPE_REGISTER_TOKEN_METADATA = 6;

    address internal constant TOKEN_FACTORY_DEPLOYER = address(0);

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
    ) {
        if (tokenManagerDeployer_ == address(0)) revert InvalidAddress();
        if (interchainTokenDeployer_ == address(0)) revert InvalidAddress();
        if (gateway_ == address(0)) revert InvalidAddress();
        if (gasService_ == address(0)) revert InvalidAddress();
        if (interchainTokenFactory_ == address(0)) revert InvalidAddress();
        if (tokenManagerImplementation_ == address(0)) revert InvalidAddress();
        if (tokenHandler_ == address(0)) revert InvalidAddress();

        tokenManagerDeployer = tokenManagerDeployer_;
        interchainTokenDeployer = interchainTokenDeployer_;
        gateway = IAxelarGateway(gateway_);
        gasService = IAxelarGasService(gasService_);
        interchainTokenFactory = interchainTokenFactory_;
        chainNameHash = keccak256(abi.encodePacked(chainName_));
        tokenManager = tokenManagerImplementation_;
        tokenHandler = tokenHandler_;

        _setItsHubAddress(itsHubAddress_);
    }

    // ============ Virtual Functions for Chain-Specific Implementations ============

    /**
     * @notice Virtual function for deploying interchain tokens
     * @dev Override this function for chain-specific token deployment logic
     */
    function _deployInterchainToken(
        bytes32 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address owner,
        bytes memory operator
    ) internal virtual returns (address tokenAddress);

    /**
     * @notice Virtual function for getting token address
     * @dev Override this function for chain-specific address resolution
     */
    function _getTokenAddress(bytes32 tokenId) internal view virtual returns (address tokenAddress);

    /**
     * @notice Virtual function for token creation pricing
     * @dev Override this function for chain-specific pricing logic
     */
    function _getTokenCreationPrice() internal view virtual returns (uint256 price);

    /**
     * @notice Virtual function for token transfer logic
     * @dev Override this function for chain-specific transfer mechanisms
     */
    function _transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool success);

    /**
     * @notice Virtual function for token minting logic
     * @dev Override this function for chain-specific minting mechanisms
     */
    function _mintToken(
        address token,
        address to,
        uint256 amount
    ) internal virtual returns (bool success);

    /**
     * @notice Virtual function for token burning logic
     * @dev Override this function for chain-specific burning mechanisms
     */
    function _burnToken(
        address token,
        address from,
        uint256 amount
    ) internal virtual returns (bool success);

    // ============ Core ITS Functions (Common Implementation) ============

    // ... existing core functions will be implemented here with calls to virtual functions
} 