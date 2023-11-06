// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { IImplementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IImplementation.sol';
import { Implementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Implementation.sol';

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';

import { BaseInterchainToken } from './BaseInterchainToken.sol';
import { ERC20Permit } from './ERC20Permit.sol';
import { Distributable } from '../utils/Distributable.sol';

/**
 * @title InterchainToken
 * @notice This contract implements a interchain token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
contract InterchainToken is BaseInterchainToken, ERC20Permit, Implementation, Distributable, IInterchainToken {
    using AddressBytes for bytes;

    string public name;
    string public symbol;
    uint8 public decimals;
    address internal tokenManager_;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token');

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure override returns (bytes32) {
        return CONTRACT_ID;
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
     * @param params The setup parameters in bytes
     * The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo
     */
    function setup(bytes calldata params) external override(Implementation, IImplementation) onlyProxy {
        address distributor;
        address tokenManagerAddress;
        string memory tokenName;
        (tokenManagerAddress, distributor, tokenName, symbol, decimals) = abi.decode(params, (address, address, string, string, uint8));

        if (tokenManagerAddress == address(0)) revert TokenManagerAddressZero();
        if (bytes(tokenName).length == 0) revert TokenNameEmpty();

        tokenManager_ = tokenManagerAddress;
        name = tokenName;

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
