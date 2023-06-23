// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20BurnableMintable } from '../../interfaces/IERC20BurnableMintable.sol';

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenCall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/SafeTransfer.sol';

/**
 * @title TokenManagerMintBurn
 * @notice This contract is an implementation of TokenManager that mints and burns a specific token on behalf of the interchain token service.
 * @dev This contract extends TokenManagerAddressStorage and provides implementation for its abstract methods.
 * It uses the Axelar SDK to safely transfer tokens.
 */
contract TokenManagerMintBurn is TokenManagerAddressStorage {
    /**
     * @dev Constructs an instance of TokenManagerMintBurn. Calls the constructor
     * of TokenManagerAddressStorage which calls the constructor of TokenManager.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManagerAddressStorage(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function implementationType() external pure returns (uint256) {
        return 1;
    }

    /**
     * @dev Sets up the token address.
     * @param params The setup parameters in bytes. Should be encoded with the token address.
     */
    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        (, address tokenAddress) = abi.decode(params, (bytes, address));
        _setTokenAddress(tokenAddress);
    }

    /**
     * @dev Burns the specified amount of tokens from a particular address.
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     * @return uint Amount of tokens burned
     */
    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.burn.selector, from, amount));

        return amount;
    }

    /**
     * @dev Mints the specified amount of tokens to a particular address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     * @return uint Amount of tokens minted
     */
    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        IERC20 token = IERC20(tokenAddress());

        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, to, amount));

        return amount;
    }
}
