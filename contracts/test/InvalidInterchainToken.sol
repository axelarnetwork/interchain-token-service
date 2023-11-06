// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { Implementation } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Implementation.sol';

import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';

import { BaseInterchainToken } from '../interchain-token/BaseInterchainToken.sol';
import { ERC20Permit } from '../interchain-token/ERC20Permit.sol';
import { Distributable } from '../utils/Distributable.sol';

contract InvalidInterchainToken is IERC20MintableBurnable, BaseInterchainToken, ERC20Permit, Implementation, Distributable {
    using AddressBytes for bytes;

    string public name;
    string public symbol;
    uint8 public decimals;
    address internal tokenManager_;

    bytes32 private constant CONTRACT_ID = keccak256('invalid-interchain-token');

    /**
     * @notice Getter for the contract id.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Returns the token manager for this token
     * @return address The token manager contract
     */
    function tokenManager() public view override returns (address) {
        return tokenManager_;
    }

    /**
     * @notice Setup function to initialize contract parameters
     * @param params The setup parameters in bytes
     * The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo
     */
    function setup(bytes calldata params) external override onlyProxy {
        {
            address distributor_;
            address tokenManagerAddress;
            string memory tokenName;
            (tokenManagerAddress, distributor_, tokenName, symbol, decimals) = abi.decode(
                params,
                (address, address, string, string, uint8)
            );

            tokenManager_ = tokenManagerAddress;
            name = tokenName;

            _addDistributor(distributor_);
            _addDistributor(tokenManagerAddress);
            _setNameHash(tokenName);
        }
        {
            uint256 mintAmount;
            address mintTo;
            (, , , , , mintAmount, mintTo) = abi.decode(params, (address, address, string, string, uint8, uint256, address));

            if (mintAmount > 0 && mintTo != address(0)) {
                _mint(mintTo, mintAmount);
            }
        }
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
