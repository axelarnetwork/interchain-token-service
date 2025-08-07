// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseTokenManager } from './BaseTokenManager.sol';
import { Minter } from '../utils/Minter.sol';
import { HTS } from '../hedera/HTS.sol';
import { ITokenManagerType } from '../interfaces/ITokenManagerType.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';
import { RolesConstants } from '../utils/RolesConstants.sol';

/**
 * @title HederaTokenManager
 * @notice Hedera-specific implementation of TokenManager with HTS support
 * @dev Extends BaseTokenManager and adds Hedera Token Service functionality
 */
contract HederaTokenManager is BaseTokenManager, Minter, ITokenManagerType {
    uint256 internal constant INT64_MAX = uint256(uint64(type(int64).max));

    /**
     * @notice Constructs the HederaTokenManager contract.
     * @param interchainTokenService_ The address of the interchain token service.
     */
    constructor(address interchainTokenService_) BaseTokenManager(interchainTokenService_) {}

    /**
     * @notice A modifier that allows only the interchain token service or minter to execute the function.
     */
    modifier onlyServiceOrMinter() {
        if (msg.sender != interchainTokenService && !isMinter(msg.sender)) revert MissingRole(msg.sender, uint8(Roles.MINTER));
        _;
    }

    /**
     * @notice Reverts if the token manager type is not supported, or if the token is not supported.
     * @param tokenAddress_ The address of the token to check.
     * @param implementationType_ The implementation type to check.
     * @return isHtsToken True if the token is an HTS token, false otherwise.
     * @dev It's cheaper to check both the token and the implementation type in one function.
     */
    function ensureSupported(address tokenAddress_, uint256 implementationType_) external returns (bool isHtsToken) {
        isHtsToken = HTS.isToken(tokenAddress_);
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
     * @notice A function that should return the native interchain token deployment params.
     */
    function getTokenDeployInfoFromParams(
        bytes calldata params_
    ) external pure returns (bytes memory operator, string memory name, string memory symbol, uint8 decimals, uint256 price) {
        (operator, name, symbol, decimals, price) = abi.decode(params_, (bytes, string, string, uint8, uint256));
    }

    /**
     * @notice Setup function for the TokenManager.
     * @dev Overrides base setup to add HTS-specific functionality
     * @param params_ The parameters to be used to initialize the TokenManager.
     */
    function setup(bytes calldata params_) external virtual override onlyProxy {
        (bytes memory operatorBytes, address tokenAddress_, bool isHtsToken, uint256 implementationType_) = abi.decode(
            params_,
            (bytes, address, bool, uint256)
        );

        address operator = address(0);

        if (operatorBytes.length != 0) {
            operator = operatorBytes.toAddress();
        }

        /**
         * Add the provided address as a minter. If `address(0)` was provided,
         * add it as a minter to allow anyone to easily check that no custom minter was set.
         */
        _addMinter(operator);

        // If an operator is not provided, set `address(0)` as the operator.
        // This allows anyone to easily check if a custom operator was set on the token manager.
        _addAccountRoles(operator, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));
        // Add operator and flow limiter role to the service. The operator can remove the flow limiter role if they so chose and the service has no way to use the operator role for now.
        _addAccountRoles(interchainTokenService, (1 << uint8(Roles.FLOW_LIMITER)) | (1 << uint8(Roles.OPERATOR)));

        // Associate the token manager with the token
        if (isHtsToken && implementationType_ != uint256(TokenManagerType.NATIVE_INTERCHAIN_TOKEN)) {
            HTS.associateToken(address(this), tokenAddress_);
        }
    }

    /**
     * @notice A function to renew approval to the service if we need to.
     * @dev Overrides base approveService to handle HTS tokens
     */
    function approveService() external override onlyService {
        address tokenAddress_ = this.tokenAddress();
        bool isHTSToken = HTS.isToken(tokenAddress_);
        uint256 amount = isHTSToken ? INT64_MAX : UINT256_MAX;
        /**
         * @dev Some tokens may not obey the infinite approval.
         * Even so, it is unexpected to run out of allowance in practice.
         * If needed, we can upgrade to allow replenishing the allowance in the future.
         *
         * @notice HTS tokens have a maximum supply of 2^63-1 (int64.max).
         */
        IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20.approve.selector, interchainTokenService, amount));
    }

    /**
     * @notice External function to allow the service to mint tokens through the tokenManager
     * @dev Overrides base mintToken to handle HTS tokens
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param to The recipient.
     * @param amount The amount to mint.
     */
    function mintToken(address tokenAddress_, address to, uint256 amount) external override onlyServiceOrMinter {
        if (HTS.isToken(tokenAddress_)) {
            HTS.mintToken(tokenAddress_, amount);
            HTS.transferToken(tokenAddress_, address(this), to, amount);
        } else {
            IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.mint.selector, to, amount));
        }
    }

    /**
     * @notice External function to allow the service to burn tokens through the tokenManager
     * @dev Overrides base burnToken to handle HTS tokens
     * @param tokenAddress_ The address of the token, since its cheaper to pass it in instead of reading it as the token manager.
     * @param from The address to burn the token from.
     * @param amount The amount to burn.
     */
    function burnToken(address tokenAddress_, address from, uint256 amount) external override onlyServiceOrMinter {
        if (HTS.isToken(tokenAddress_)) {
            HTS.transferFrom(tokenAddress_, from, address(this), amount);
            HTS.burnToken(tokenAddress_, amount);
        } else {
            IERC20(tokenAddress_).safeCall(abi.encodeWithSelector(IERC20MintableBurnable.burn.selector, from, amount));
        }
    }
} 
