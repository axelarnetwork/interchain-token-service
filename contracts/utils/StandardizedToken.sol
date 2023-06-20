// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';

import { InterchainToken } from '../interchainToken/InterchainToken.sol';
import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { ITokenManager } from '../interfaces/ITokenManager.sol';
import { Implementation } from './Implementation.sol';
import { Distributable } from '../utils/Distributable.sol';

abstract contract StandardizedToken is InterchainToken, Implementation, Distributable, IERC20BurnableMintable {
    using AddressBytesUtils for bytes;

    address public tokenManager;

    // keccak256('standardized-token'))
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0x8f0d3a2d3a4c902b07e15645c3d56cc5d37941403c982473aeb5a1c964a34cd5;

    function getTokenManager() public view override returns (ITokenManager) {
        return ITokenManager(tokenManager);
    }

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

    function mint(address account, uint256 amount) external onlyDistributor {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}
