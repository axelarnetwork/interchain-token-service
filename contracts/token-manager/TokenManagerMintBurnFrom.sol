// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';

import { IERC20BurnableFrom } from '../interfaces/IERC20BurnableFrom.sol';
import { TokenManagerMintBurn } from './TokenManagerMintBurn.sol';

/**
 * @title TokenManagerMintBurnFrom
 * @notice This contract is an implementation of TokenManager that mints and burns a specific token from a particular address on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerMintBurnFrom is TokenManagerMintBurn {
    using SafeTokenCall for IERC20;

    /**
     * @notice Constructs an instance of TokenManagerMintBurnFrom.
     * @dev Calls the constructor of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract.
     */
    constructor(address interchainTokenService_) TokenManagerMintBurn(interchainTokenService_) {}

    /**
     * @notice Getter function for the implementation type.
     * @return uint256 The implementation type.
     */
    function implementationType() external pure override returns (uint256) {
        return uint256(TokenManagerType.MINT_BURN_FROM);
    }

    /**
     * @notice Burns the specified amount of tokens from a particular address.
     * @param from Address to burn tokens from.
     * @param amount Amount of tokens to burn.
     * @return uint256 Amount of tokens burned.
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        token.safeCall(abi.encodeWithSelector(IERC20BurnableFrom.burnFrom.selector, from, amount));

        return amount;
    }
}
