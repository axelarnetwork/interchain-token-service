// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenCall, SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

import { IERC20BurnableFrom } from '../../interfaces/IERC20BurnableFrom.sol';
import { TokenManagerMintBurn } from './TokenManagerMintBurn.sol';

/**
 * @title TokenManagerMintBurn
 * @notice This contract is an implementation of TokenManager that mints and burns a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerMintBurnFromAddress is TokenManagerMintBurn {
    using SafeTokenCall for IERC20;
    using SafeTokenTransferFrom for IERC20;

    /**
     * @dev Constructs an instance of TokenManagerMintBurn. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManagerMintBurn(interchainTokenService_) {}

    function implementationType() external pure override returns (uint256) {
        return 2;
    }

    /**
     * @dev Burns the specified amount of tokens from a particular address.
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     * @return uint Amount of tokens burned
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        address tokenAddress_ = tokenAddress();
        IERC20 token = IERC20(tokenAddress_);

        token.safeTransferFrom(from, IERC20BurnableFrom(tokenAddress_).depositAddress(bytes32(0)), amount);
        token.safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burn.selector, bytes32(0)));

        return amount;
    }
}
