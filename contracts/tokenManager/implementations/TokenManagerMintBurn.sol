// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20BurnableMintable } from '../../interfaces/IERC20BurnableMintable.sol';

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';



contract TokenManagerMintBurn is TokenManagerAddressStorage {
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManagerAddressStorage(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function requiresApproval() external pure returns (bool) {
        return false;
    }

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, address tokenAddress) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress);
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.burn.selector, from, amount));

        return amount;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, to, amount));

        return amount;
    }
}
