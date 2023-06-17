// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { Implementation } from './Implementation.sol';
import { Distributable } from '../utils/Distributable.sol';

contract StandardizedToken is InterchainToken, Implementation, Distributable, IERC20BurnableMintable {
    using AddressBytesUtils for bytes;

    address public tokenManager;
    bool public tokenManagerRequiresApproval_;

    // bytes32(uint256(keccak256('standardized-token')) - 1)
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf1ebb9a018916df92653eef7dc1160cdec8e19ba8f75f1500287c87894dc8db7;

    function getTokenManager() public view override returns (ITokenManager) {
        return ITokenManager(tokenManager);
    }

    function tokenManagerRequiresApproval() public view override returns (bool) {
        return tokenManagerRequiresApproval_;
    }

    function setup(bytes calldata params) external override onlyProxy {
        {
            address distributor_;
            address tokenManager_;
            string memory tokenName;
            (tokenManager_, distributor_, tokenName, symbol, decimals) = abi.decode(params, (address, address, string, string, uint8));
            _setDistributor(distributor_);
            tokenManager = tokenManager_;
            tokenManagerRequiresApproval_ = distributor_ != tokenManager;
            _setDomainTypeSignatureHash(tokenName);
            name = tokenName;
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

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
