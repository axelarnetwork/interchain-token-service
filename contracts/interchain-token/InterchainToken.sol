// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';

import { BaseInterchainToken } from './BaseInterchainToken.sol';
import { ERC20Permit } from './ERC20Permit.sol';
import { Distributable } from '../utils/Distributable.sol';

/**
 * @title InterchainToken
 * @notice This contract implements a interchain token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
contract InterchainToken is BaseInterchainToken, ERC20Permit, Distributable, IInterchainToken {
    using AddressBytes for bytes;

    string public name;
    string public symbol;
    uint8 public decimals;
    address internal tokenManager_;

    // bytes32(uint256(keccak256('interchain-token-is-setup-slot')) - 1);
    bytes32 internal constant IS_SETUP_SLOT = 0xb39f35de0a5b2620db9237c1e18c03b5e68a71236c9bdfbcd69f3582bab06df6;

    constructor() {
        // Make the implementation act as if it has been setup already to disallow calls to init() (even though that wouldn't achieve anything really)
        _setSetup();
    }

    /**
     * @notice returns true if the contract has be setup.
     */
    function _isSetup() internal view returns (bool isSetup) {
        assembly {
            isSetup := sload(IS_SETUP_SLOT)
        }
    }

    /**
     * @notice sets the isSetup to true, to allow only a single setup.
     */
    function _setSetup() internal {
        assembly {
            sstore(IS_SETUP_SLOT, true)
        }
    }

    /**
     * @notice Returns the token manager for this token
     * @return address The token manager contract
     */
    function tokenManager() public view override(BaseInterchainToken, IInterchainToken) returns (address) {
        return tokenManager_;
    }

    /**
     * @notice Setup function to initialize contract parameters
     * @param tokenManagerAddress The address of the token manager of this token
     * @param distributor The address of the token distributor
     * @param tokenName The name of the token
     * @param tokenSymbol The symbopl of the token
     * @param tokenDecimals The decimals of the token
     */
    function init(
        address tokenManagerAddress,
        address distributor,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external {
        if (_isSetup()) revert AlreadySetup();
        _setSetup();

        if (tokenManagerAddress == address(0)) revert TokenManagerAddressZero();
        if (bytes(tokenName).length == 0) revert TokenNameEmpty();

        tokenManager_ = tokenManagerAddress;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;

        if (distributor != address(0)) _addDistributor(distributor);
        _addDistributor(tokenManagerAddress);

        _setNameHash(tokenName);
    }

    /**
     * @notice Function to mint new tokens
     * Can only be called by the distributor address.
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _mint(account, amount);
    }

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param account The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _burn(account, amount);
    }
}
