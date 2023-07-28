// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ITokenManagerGetter } from '../interfaces/ITokenManagerGetter.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';

/**
 * @title TokenManagerDeployer
 * @notice This contract is used to deploy new instances of the TokenManagerProxy contract.
 */
contract TokenManagerGetter is ITokenManagerGetter {
    address internal immutable implementationLockUnlock;
    address internal immutable implementationMintBurn;
    address internal immutable implementationLockUnlockFee;
    address internal immutable implementationLiquidityPool;

    constructor(address[] memory tokenManagerImplementations) {
        if (tokenManagerImplementations.length != uint256(type(TokenManagerType).max) + 1) revert LengthMismatch();

        implementationLockUnlock = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LOCK_UNLOCK);
        implementationMintBurn = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.MINT_BURN);
        implementationLockUnlockFee = _sanitizeTokenManagerImplementation(
            tokenManagerImplementations,
            TokenManagerType.LOCK_UNLOCK_FEE_ON_TRANSFER
        );
        implementationLiquidityPool = _sanitizeTokenManagerImplementation(tokenManagerImplementations, TokenManagerType.LIQUIDITY_POOL);
    }

    function _sanitizeTokenManagerImplementation(
        address[] memory implementaions,
        TokenManagerType tokenManagerType
    ) internal pure returns (address implementation) {
        implementation = implementaions[uint256(tokenManagerType)];
        if (implementation == address(0)) revert ZeroAddress();
        if (ITokenManager(implementation).implementationType() != uint256(tokenManagerType)) revert InvalidTokenManagerImplementation();
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLockUnlock(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a mint/burn TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsMintBurn(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a lock/unlock TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLockUnlockFee(bytes memory operator, address tokenAddress) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress);
    }

    /**
     * @notice Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.
     * @param operator the operator of the TokenManager.
     * @param tokenAddress the token to be managed.
     * @param liquidityPoolAddress the liquidity pool to be used to store the bridged tokens.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParamsLiquidityPool(
        bytes memory operator,
        address tokenAddress,
        address liquidityPoolAddress
    ) public pure returns (bytes memory params) {
        params = abi.encode(operator, tokenAddress, liquidityPoolAddress);
    }

    /**
     * @notice Getter function for TokenManager implementations. This will mainly be called by TokenManagerProxies
     * to figure out their implementations
     * @param tokenManagerType the type of the TokenManager.
     * @return tokenManagerAddress the address of the TokenManagerImplementation.
     */
    function getImplementation(uint256 tokenManagerType) external view returns (address tokenManagerAddress) {
        if (tokenManagerType > uint256(type(TokenManagerType).max)) revert InvalidTokenManagerImplementation();
        if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK) {
            return implementationLockUnlock;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.MINT_BURN) {
            return implementationMintBurn;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.LOCK_UNLOCK_FEE_ON_TRANSFER) {
            return implementationLockUnlockFee;
        } else if (TokenManagerType(tokenManagerType) == TokenManagerType.LIQUIDITY_POOL) {
            return implementationLiquidityPool;
        }
    }
}
