// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';

import { ITokenManagerLiquidityPool } from '../../interfaces/ITokenManagerLiquidityPool.sol';
import { TokenManager } from '../TokenManager.sol';
import { NoReEntrancy } from '../../utils/NoReEntrancy.sol';

/**
 * @title TokenManagerLiquidityPool
 * @notice This contract is a an implementation of TokenManager that stores all tokens in a separate liquity pool
 * rather than within itself.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerLiquidityPool is TokenManager, NoReEntrancy, ITokenManagerLiquidityPool {
    using SafeTokenTransferFrom for IERC20;

    // uint256(keccak256('liquidity-pool-slot')) - 1
    uint256 internal constant LIQUIDITY_POOL_SLOT = 0x8e02741a3381812d092c5689c9fc701c5185c1742fdf7954c4c4472be4cc4807;

    /**
     * @dev Constructs an instance of TokenManagerLiquidityPool. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    function implementationType() external pure returns (uint256) {
        revert('Not supported');
    }

    /**
     * @dev Sets up the token address and liquidity pool address.
     * @param params The setup parameters in bytes. Should be encoded with the token address and the liquidity pool address.
     */
    function _setup(bytes calldata params) internal override {
        // The first argument is reserved for the operator.
        (, address tokenAddress_, address liquidityPool_) = abi.decode(params, (bytes, address, address));
        _setTokenAddress(tokenAddress_);
        _setLiquidityPool(liquidityPool_);
    }

    /**
     * @dev Stores the liquidity pool address at a specific storage slot
     * @param liquidityPool_ The address of the liquidity pool
     */
    function _setLiquidityPool(address liquidityPool_) internal {
        assembly {
            sstore(LIQUIDITY_POOL_SLOT, liquidityPool_)
        }
    }

    /**
     * @dev Reads the stored liquidity pool address from the specified storage slot
     * @return liquidityPool_ The address of the liquidity pool
     */
    function liquidityPool() public view returns (address liquidityPool_) {
        assembly {
            liquidityPool_ := sload(LIQUIDITY_POOL_SLOT)
        }
    }

    /**
     * @dev Updates the address of the liquidity pool. Can only be called by the operator.
     * @param newLiquidityPool The new address of the liquidity pool
     */
    function setLiquidityPool(address newLiquidityPool) external onlyOperator {
        _setLiquidityPool(newLiquidityPool);
    }

    /**
     * @dev Transfers a specified amount of tokens from a specified address to the liquidity pool.
     * @param from The address to transfer tokens from
     * @param amount The amount of tokens to transfer
     * @return uint The actual amount of tokens transferred. This allows support for fee-on-transfer tokens.
     */
    function _takeToken(address from, uint256 amount) internal override noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        address liquidityPool_ = liquidityPool();
        uint256 balance = token.balanceOf(liquidityPool_);

        token.safeTransferFrom(from, liquidityPool_, amount);

        uint256 diff = token.balanceOf(liquidityPool_) - balance;
        if (diff < amount) {
            amount = diff;
        }
        return amount;
    }

    /**
     * @dev Transfers a specified amount of tokens from the liquidity pool to a specified address.
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return uint The actual amount of tokens transferred
     */
    function _giveToken(address to, uint256 amount) internal override noReEntrancy returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = token.balanceOf(to);

        // slither-disable-next-line arbitrary-send-erc20
        token.safeTransferFrom(liquidityPool(), to, amount);

        uint256 diff = token.balanceOf(to) - balance;
        if (diff < amount) {
            amount = diff;
        }
        return amount;
    }

    /**
     * @notice Getter function for the parameters of a liquidity pool TokenManager. Mainly to be used by frontends.
     * @param operator_ the operator of the TokenManager.
     * @param tokenAddress_ the token to be managed.
     * @param liquidityPoolAddress the liquidity pool to be used to store the bridged tokens.
     * @return params the resulting params to be passed to custom TokenManager deployments.
     */
    function getParams(
        bytes memory operator_,
        address tokenAddress_,
        address liquidityPoolAddress
    ) external pure returns (bytes memory params) {
        params = abi.encode(operator_, tokenAddress_, liquidityPoolAddress);
    }
}
