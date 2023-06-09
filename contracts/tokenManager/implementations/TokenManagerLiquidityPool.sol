// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

contract TokenManagerLiquidityPool is TokenManagerAddressStorage {
    // uint256(keccak256('liquidity-pool-slot')) - 1
    uint256 internal constant LIQUIDITY_POOL_SLOT = 0x8e02741a3381812d092c5689c9fc701c5185c1742fdf7954c4c4472be4cc4807;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManagerAddressStorage(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function requiresApproval() external pure returns (bool) {
        return true;
    }

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, address tokenAddress_, address liquidityPool_) = abi.decode(params, (bytes, address, address));
        _setTokenAddress(tokenAddress_);
        _setLiquidityPool(liquidityPool_);
    }

    function _setLiquidityPool(address liquidityPool_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(LIQUIDITY_POOL_SLOT, liquidityPool_)
        }
    }

    function liquidityPool() public view returns (address liquidityPool_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            liquidityPool_ := sload(LIQUIDITY_POOL_SLOT)
        }
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        address liquidityPool_ = liquidityPool();
        uint256 balance = token.balanceOf(liquidityPool_);

        SafeTokenTransferFrom.safeTransferFrom(token, from, liquidityPool_, amount);

        // Note: This allows support for fee-on-transfer tokens
        return IERC20(token).balanceOf(liquidityPool_) - balance;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());
        uint256 balance = IERC20(token).balanceOf(to);

        SafeTokenTransferFrom.safeTransferFrom(token, liquidityPool(), to, amount);

        return IERC20(token).balanceOf(to) - balance;
    }
}
