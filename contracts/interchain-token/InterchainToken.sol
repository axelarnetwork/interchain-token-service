// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';

import { IInterchainToken } from '../interfaces/IInterchainToken.sol';

import { BaseInterchainToken } from './BaseInterchainToken.sol';
import { ERC20Permit } from './ERC20Permit.sol';
import { Distributable } from '../utils/Distributable.sol';

/**
 * @title InterchainToken
 * @notice This contract implements an interchain token which extends InterchainToken functionality.
 * @dev This contract also inherits Distributable and Implementation logic.
 */
contract InterchainToken is BaseInterchainToken, ERC20Permit, Distributable, IInterchainToken {
    using AddressBytes for bytes;

    string public name;
    string public symbol;
    uint8 public decimals;
    bytes32 internal tokenId;
    address internal immutable interchainTokenService_;

    // bytes32(uint256(keccak256('interchain-token-initialized')) - 1);
    bytes32 internal constant INITIALIZED_SLOT = 0xc778385ecb3e8cecb82223fa1f343ec6865b2d64c65b0c15c7e8aef225d9e214;

    /**
     * @notice Constructs the InterchainToken contract.
     * @dev Makes the implementation act as if it has been setup already to disallow calls to init() (even though that would not achieve anything really).
     */
    constructor(address interchainTokenServiceAddress) {
        _initialize();

        if (interchainTokenServiceAddress == address(0)) revert InterchainTokenServiceAddressZero();

        interchainTokenService_ = interchainTokenServiceAddress;
    }

    /**
     * @notice Returns true if the contract has been setup.
     * @return initialized True if the contract has been setup, false otherwise.
     */
    function _isInitialized() internal view returns (bool initialized) {
        assembly {
            initialized := sload(INITIALIZED_SLOT)
        }
    }

    /**
     * @notice Sets initialized to true, to allow only a single init.
     */
    function _initialize() internal {
        assembly {
            sstore(INITIALIZED_SLOT, true)
        }
    }

    /**
     * @notice Returns the interchain token service
     * @return address The interchain token service contract
     */
    function interchainTokenService() public view override(BaseInterchainToken, IInterchainToken) returns (address) {
        return interchainTokenService_;
    }

    /**
     * @notice Returns the tokenId for this token.
     * @return bytes32 The token manager contract.
     */
    function interchainTokenId() public view override(BaseInterchainToken, IInterchainToken) returns (bytes32) {
        return tokenId;
    }

    /**
     * @notice Setup function to initialize contract parameters.
     * @param tokenId_ The tokenId of the token.
     * @param distributor The address of the token distributor.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbopl of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function init(
        bytes32 tokenId_,
        address distributor,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external {
        if (_isInitialized()) revert AlreadyInitialized();

        _initialize();

        if (tokenId_ == bytes32(0)) revert TokenIdZero();
        if (bytes(tokenName).length == 0) revert TokenNameEmpty();

        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        tokenId = tokenId_;

        /**
         * @dev Set the token service as a distributor to allow it to mint and burn tokens.
         * Also add the provided address as a distributor. If `address(0)` was provided,
         * add it as a distributor to allow anyone to easily check that no custom distributor was set.
         */
        _addDistributor(interchainTokenService_);
        _addDistributor(distributor);

        _setNameHash(tokenName);
    }

    /**
     * @notice Function to mint new tokens.
     * @dev Can only be called by the distributor address.
     * @param account The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _mint(account, amount);
    }

    /**
     * @notice Function to burn tokens.
     * @dev Can only be called by the distributor address.
     * @param account The address that will have its tokens burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address account, uint256 amount) external onlyRole(uint8(Roles.DISTRIBUTOR)) {
        _burn(account, amount);
    }
}
