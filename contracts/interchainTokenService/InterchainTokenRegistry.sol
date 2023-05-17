// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { EternalStorage } from '@axelar-network/axelar-cgp-solidity/contracts/EternalStorage.sol';

import { IInterchainTokenRegistry } from '../interfaces/IInterchainTokenRegistry.sol';
import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { ITokenLinker } from '../interfaces/ITokenLinker.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

contract InterchainTokenRegistry is IInterchainTokenRegistry, AxelarExecutable, EternalStorage, Upgradable {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using LinkedTokenData for bytes32;
    using AddressBytesUtils for bytes;

    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    ITokenDeployer public immutable tokenDeployer;
    IExpressCallHandler public immutable expressCallHandler;

    bytes32 internal constant PREFIX_TOKEN_DATA = keccak256('itl-token-data');
    bytes32 internal constant PREFIX_ORIGINAL_CHAIN = keccak256('itl-original-chain');
    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('itl-token-id');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('itl-token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('itl-token-mint-amount');
    bytes32 internal constant PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID = keccak256('itl-custom-interchain-token-id');

    uint256 constant SEND_TOKEN_SELECTOR = 1;
    uint256 constant SEND_TOKEN_WITH_DATA_SELECTOR = 2;

    // keccak256('interchain-token-service')-1
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    constructor(
        address gatewayAddress_,
        address gasServiceAddress_,
        address linkerRouterAddress_,
        address tokenDeployerAddress_,
        address expressCallHandlerAddress_,
        string memory chainName_
    ) AxelarExecutable(gatewayAddress_) {
        if (gatewayAddress_ == address(0) || gasServiceAddress_ == address(0) || linkerRouterAddress_ == address(0))
            revert TokenServiceZeroAddress();
        gasService = IAxelarGasService(gasServiceAddress_);
        linkerRouter = ILinkerRouter(linkerRouterAddress_);
        tokenDeployer = ITokenDeployer(tokenDeployerAddress_);
        expressCallHandler = IExpressCallHandler(expressCallHandlerAddress_);
        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) return;
        _;
    }

    modifier onlyTokenLinker(bytes32 tokenId) {
        if(msg.sender != getTokenLinkerAddress(tokenId)) revert NotTokenLinker();
        _;
    }

    function getTokenId(address sender, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID, sender, salt));
    }

    function getTokenLinkerAddress(bytes32 tokenId) public view returns (address deployment) {
        deployment = tokenDeployer.getDeploymentAddress(address(this), tokenId);
    }

    /* EXTERNAL FUNCTIONS */



    function registerToken(bytes32 salt, address tokenAddress, bytes calldata params) external returns (bytes32 tokenId) {
        _validateOriginToken(tokenAddress);
        tokenId = getTokenId(msg.sender, salt);
        _registerToken(tokenAddress, tokenId, params);
    }

   function sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external payable onlyTokenLinker(tokenId){
        bytes memory payload = abi.encode(SEND_TOKEN_SELECTOR, destinationAddress, amount);
        _callContract(destinationChain, payload, msg.value);
    }

    // UTILITY FUNCTIONS

    function _registerToken(address tokenAddress, bytes32 tokenId, bytes calldata params) internal {
        emit TokenRegistered(tokenId, tokenAddress);
    }

    function _validateOriginToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    function _callContract(string memory destinationChain, bytes memory payload, uint256 gasValue) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /* EXECUTE AND EXECUTE WITH TOKEN */

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        //TODO: implement
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata /*symbol*/,
        uint256 /*amount*/
    ) internal override {
        _execute(sourceChain, sourceAddress, payload);
    }
}
