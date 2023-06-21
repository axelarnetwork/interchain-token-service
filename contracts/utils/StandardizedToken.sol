// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { Implementation } from './Implementation.sol';
import { Distributable } from '../utils/Distributable.sol';

/**
 * @title StandardizedToken
 * @author Foivos Antoulinakis
 * @notice This contract implements a standardized token which extends InterchainToken functionality.
 * This contract also inherits Distributable and Implementation logic.
 */
abstract contract StandardizedToken is InterchainToken, Implementation, Distributable, IERC20BurnableMintable {
    using AddressBytesUtils for bytes;

    address public tokenManager;

    // keccak256('standardized-token'))
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0x8f0d3a2d3a4c902b07e15645c3d56cc5d37941403c982473aeb5a1c964a34cd5;

    /**
     * @notice Returns the token manager for this token
     * @return ITokenManager The token manager contract
     */
    function getTokenManager() public view override returns (ITokenManager) {
        return ITokenManager(tokenManager);
    }

    /**
     * @notice Setup function to initialize contract parameters
     * @param params The setup parameters in bytes
     * The setup params include tokenManager, distributor, tokenName, symbol, decimals, mintAmount and mintTo
     */
    function setup(bytes calldata params) external override onlyProxy {
        {
            address distributor_;
            address tokenManager_;
            string memory tokenName;
            (tokenManager_, distributor_, tokenName, symbol, decimals) = abi.decode(params, (address, address, string, string, uint8));
            _setDistributor(distributor_);
            tokenManager = tokenManager_;
            _setDomainTypeSignatureHash(tokenName);
            name = tokenName;
            // TODO: symbol, decimals aren't being set
        }
        {
            uint256 mintAmount;
            address mintTo;
            (, , , , , mintAmount, mintTo) = abi.decode(params, (address, address, string, string, uint8, uint256, address));
            if (mintAmount > 0) {
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
    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    /**
     * @notice Function to burn tokens
     * Can only be called by the distributor address.
     * @param account The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
