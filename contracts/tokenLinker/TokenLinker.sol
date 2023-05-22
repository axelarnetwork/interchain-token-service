// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { EternalStorage } from '@axelar-network/axelar-cgp-solidity/contracts/EternalStorage.sol';

import { IInterchainTokenRegistry } from '../interfaces/IInterchainTokenRegistry.sol';
import { ITokenLinker } from '../interfaces/ITokenLinker.sol';
import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

abstract contract TokenLinker is ITokenLinker {
    using AddressBytesUtils for bytes;

    IInterchainTokenRegistry public immutable interchainTokenService;
    address public tokenAddress;
    bytes32 public tokenId;
    address public admin;

    address private immutable implementationAddress;

    uint256 constant SEND_TOKEN_SELECTOR = 1;
    uint256 constant SEND_TOKEN_WITH_DATA_SELECTOR = 2;

    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert TokenLinkerZeroAddress();
        interchainTokenService = IInterchainTokenRegistry(interchainTokenService_);
        implementationAddress = address(this);
    }

    modifier onlyService() {
        if (msg.sender != address(interchainTokenService)) revert NotService();
        _;
    }

    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    function setup(bytes calldata params) external onlyProxy {
        (tokenAddress, admin) = abi.decode(params, (address, address));
        _setup(params);
    }

    function sendToken(string calldata destiantionChain, bytes calldata destinationAddress, uint256 amount) external payable {
        amount = _takeToken(msg.sender, amount);
        interchainTokenService.sendToken{ value: msg.value }(tokenId, destiantionChain, destinationAddress, amount);
    }

    function callContractWithInterchainToken(
        string calldata destiantionChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable {
        amount = _takeToken(msg.sender, amount);
        interchainTokenService.sendTokenWithData{ value: msg.value }(
            tokenId,
            msg.sender,
            destiantionChain,
            destinationAddress,
            amount,
            data
        );
    }

    function giveToken(address destinationAddress, uint256 amount) external onlyService returns (uint256) {
        return _giveToken(destinationAddress, amount);
    }

    function _takeToken(address from, uint256 amount) internal virtual returns (uint256);

    function _giveToken(address to, uint256 amount) internal virtual returns (uint256);

    function _setup(bytes calldata params) internal virtual {}
}
