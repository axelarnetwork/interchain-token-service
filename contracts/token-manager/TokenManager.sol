// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';
import { Implementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Implementation.sol';
import { SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';

import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';

import { Operator } from '../utils/Operator.sol';
import { FlowLimit } from '../utils/FlowLimit.sol';

import { HTS } from '../hedera/HTS.sol';
import { Minter } from '../utils/Minter.sol';

/**
 * @title TokenManager
 * @notice This contract is responsible for managing tokens, such as setting locking token balances, or setting flow limits, for interchain transfers.
 */
contract TokenManager is ITokenManager, Minter, Operator, FlowLimit, Implementation, Multicall {
    using AddressBytes for bytes;
    using SafeTokenCall for IERC20;

    uint256 internal constant UINT256_MAX = type(uint256).max;

    address public immutable interchainTokenService;

    bytes32 private constant CONTRACT_ID = keccak256('token-manager');

    /**
     * @notice Constructs the TokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service.
     */
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();

        interchainTokenService = interchainTokenService_;
    }

    /**
     * @notice A modifier that allows only the interchain token service to execute the function.
     */
    modifier onlyService() {
        if (msg.sender != interchainTokenService) revert NotService(msg.sender);
        _;
    }

    /**
     * @notice A modifier that allows only the interchain token service to execute the function.
     */
    modifier onlyServiceOrMinter() {
        if (msg.sender != interchainTokenService && !isMinter(msg.sender)) revert MissingRole(msg.sender, uint8(Roles.MINTER));
        _;
    }

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id.
     */
    function contractId() external pure override returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Reads the token address from the proxy.
     * @dev This function is not supported when directly called on the implementation. It
     * must be called by the proxy.
     * @return tokenAddress_ The address of the token.
     */
    function tokenAddress() external view virtual returns (address) {
        revert NotSupported();
    }

    /**
     * @notice A function that returns the token id.
     * @dev This will only work when implementation is called by a proxy, which stores the tokenId as an immutable.
     * @return bytes32 The interchain token ID.
     */
    function interchainTokenId() public pure returns (bytes32) {
        revert NotSupported();
    }

    /**
     * @notice Returns implementation type of this token manager.
     * @return uint256 The implementation type of this token manager.
     */
    function implementationType() external pure returns (uint256) {
        revert NotSupported();
    }

    /**
     * @notice Reverts if the token manager type is not supported, or if the token is not supported.
     * If the token is a supported HTS token, the Token Manager will associate itself with the token.
     * @param tokenAddress_ The address of the token to check.
     * @param implementationType_ The implementation type to check.
     * @dev It's cheaper to check both the token and the implementation type in one function.
     */
    function ensureSupported(address tokenAddress_, uint256 implementationType_) external {
        bool isHtsToken = HTS.isToken(tokenAddress_);
        if (isHtsToken) {
            // Currently MINT_BURN and MINT_BURN_FROM are not supported for HTS tokens
            // See contracts/hedera/README.md for more information
            if (
                implementationType_ == uint256(TokenManagerType.MINT_BURN) ||
                implementationType_ == uint256(TokenManagerType.MINT_BURN_FROM)
            ) {
                revert ManagerTypeNotSupported();
            }

            // Check if token is supported
            if (!HTS.isTokenSupportedByITS(tokenAddress_)) {
                revert HTS.TokenUnsupported();
            }
        }
    }

    /**
     * @notice A function that should return the token address from the setup params.
     * @param params_ The setup parameters.
     * @return tokenAddress_ The token address.
     */
    function getTokenAddressFromParams(bytes calldata params_) external pure returns (address tokenAddress_) {
        (, tokenAddress_) = abi.decode(params_, (bytes, address));
    }

    /**
     * @notice A function that should return the native interchain token deployment params.
     */
    function getTokenDeployInfoFromParams(
        bytes calldata params_
    ) external pure returns (bytes memory operator, string memory name, string memory symbol, uint8 decimals, uint256 price) {
        (operator, name, symbol, decimals, price) = abi.decode(params_, (bytes, string, string, uint8, uint256));
    }

    /**
     * @notice Setup function for the TokenManager.
     * @dev This function should only be called by the proxy, and only once from the proxy constructor.
     * The exact format of params depends on the type of TokenManager used but the first 32 bytes are reserved
     * for the address of the operator, stored as bytes (to be compatible with non-EVM chains)
     * @param params_ The parameters to be used to initialize the TokenManager.
     */
    function setup(bytes calldata params_) external override(Implementation, IImplementation) onlyProxy {
        (bytes memory operatorBytes, address tokenAddress_) = abi.decode(params_, (bytes, address));

        address operator = address(0);

        if (operatorBytes.length != 0) {
            operator = operatorBytes.toAddress();
        }

        /**
         * @dev Set the token service as a minter to allow it to mint and burn tokens.
         * Also add the provided address as a minter. If `address(0)` was provided,
         * add it as a minter to allow anyone to easily check that no custom minter was set.
         */
        // TODO(hedera) should we add the service as a minter?
        _addMinter(interchainTokenService);
        _addMinter(operator);

        // If an operator is not provided, set `address(0)` as the operator.
        // This allows anyone to easily check if a custom operator was set on the token manager.
        _addAccountRoles(operator, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));
        // Add operator and flow limiter role to the service. The operator can remove the flow limiter role if they so chose and the service has no way to use the operator role for now.
        _addAccountRoles(interchainTokenService, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));

        // Associate the token manager with the token
        // TODO(hedera) this should be done only if token manager type is LOCK_UNLOCK?
        // is it more expensive to check or associate either way?
        HTS.associateToken(address(this), tokenAddress_);
    }

    function addFlowIn(uint256 amount) external onlyService {
        _addFlowIn(amount);
    }

    function addFlowOut(uint256 amount) external onlyService {
        _addFlowOut(amount);
    }

    /**
     * @notice This function transfers a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param from the address of the old flow limiter.
     * @param to the address of the new flow limiter.
     */
    function transferFlowLimiter(address from, address to) external onlyRole(uint8(Roles.OPERATOR)) {
        _transferAccountRoles(from, to, 1 << uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function adds a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of the new flow limiter.
     */
    function addFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        _addRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function removes a flow limiter for this TokenManager.
     * @dev Can only be called by the operator.
     * @param flowLimiter the address of an existing flow limiter.
     */
    function removeFlowLimiter(address flowLimiter) external onlyRole(uint8(Roles.OPERATOR)) {
        _removeRole(flowLimiter, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice Query if an address is a flow limiter.
     * @param addr The address to query for.
     * @return bool Boolean value representing whether or not the address is a flow limiter.
     */
    function isFlowLimiter(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.FLOW_LIMITER));
    }

    /**
     * @notice This function sets the flow limit for this TokenManager.
     * @dev Can only be called by the flow limiters.
     * @param flowLimit_ The maximum difference between the tokens flowing in and/or out at any given interval of time (6h).
     */
    function setFlowLimit(uint256 flowLimit_) external onlyRole(uint8(Roles.FLOW_LIMITER)) {
        // slither-disable-next-line var-read-using-this
        _setFlowLimit(flowLimit_, this.interchainTokenId());
    }

    /**
     * @notice A function to renew approval to the service if we need to.
     */
    function approveService() external onlyService {
        /**
         * @dev Some tokens may not obey the infinite approval.
         * Even so, it is unexpected to run out of allowance in practice.
         * If needed, we can upgrade to allow replenishing the allowance in the future.
         */
        IERC20(this.tokenAddress()).safeCall(abi.encodeWithSelector(IERC20.approve.selector, interchainTokenService, UINT256_MAX));
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager.
     * @dev This function will be mainly used by frontends.
     * @param operator_ The operator of the TokenManager.
     * @param tokenAddress_ The token to be managed.
     * @return params_ The resulting params to be passed to custom TokenManager deployments.
     */
    function params(bytes calldata operator_, address tokenAddress_) external pure returns (bytes memory params_) {
        params_ = abi.encode(operator_, tokenAddress_);
    }

    /**
     * @notice External function to allow the service to mint tokens through the tokenManager
     * @dev This function should revert if called by anyone but the service.
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param to The recipient.
     * @param amount The amount to mint.
     */
    function mintToken(address tokenAddress_, address to, uint256 amount) external onlyServiceOrMinter {
        if (HTS.isToken(tokenAddress_)) {
            HTS.mintToken(tokenAddress_, amount);
            HTS.transferToken(tokenAddress_, address(this), to, amount);
        } else {
            IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.mint.selector, to, amount));
        }
    }

    /**
     * @notice External function to allow the service to burn tokens through the tokenManager
     * @dev This function should revert if called by anyone but the service.
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param from The address to burn the token from.
     * @param amount The amount to burn.
     */
    function burnToken(address tokenAddress_, address from, uint256 amount) external onlyServiceOrMinter {
        if (HTS.isToken(tokenAddress_)) {
            HTS.transferFrom(tokenAddress_, from, address(this), amount);
            HTS.burnToken(tokenAddress_, amount);
        } else {
            IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.burn.selector, from, amount));
        }
    }
}
