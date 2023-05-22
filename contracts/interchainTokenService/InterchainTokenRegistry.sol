// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { EternalStorage } from '@axelar-network/axelar-cgp-solidity/contracts/EternalStorage.sol';

import { IInterchainTokenRegistry } from '../interfaces/IInterchainTokenRegistry.sol';
import { TokenLinkerDeployer } from '../utils/TokenLinkerDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { ITokenLinker } from '../interfaces/ITokenLinker.sol';
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';
import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

contract InterchainTokenRegistry is IInterchainTokenRegistry, AxelarExecutable, EternalStorage, Upgradable, TokenLinkerDeployer {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using LinkedTokenData for bytes32;
    using AddressBytesUtils for bytes;
    using AddressBytesUtils for address;

    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    IExpressCallHandler public immutable expressCallHandler;

    address public immutable lockUnlockImpl;
    address public immutable mintBurnImpl;
    address public immutable deployedImpl;
    address public immutable gatewayImpl;

    bytes32 internal constant PREFIX_TOKEN_DATA = keccak256('itl-token-data');
    bytes32 internal constant PREFIX_ORIGINAL_CHAIN = keccak256('itl-original-chain');
    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('itl-token-id');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('itl-token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('itl-token-mint-amount');
    bytes32 internal constant PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID = keccak256('itl-custom-interchain-token-id');

    uint256 internal constant SEND_TOKEN_SELECTOR = 1;
    uint256 internal constant SEND_TOKEN_WITH_DATA_SELECTOR = 2;

    // keccak256('interchain-token-service')-1
    // solhint-disable-next-line const-name-snakecase
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    constructor(
        address gatewayAddress_,
        address gasServiceAddress_,
        address linkerRouterAddress_,
        address deployer_,
        address bytecodeServer_,
        address expressCallHandlerAddress_,
        address[] memory implementations,
        string memory chainName_
    ) AxelarExecutable(gatewayAddress_) TokenLinkerDeployer(deployer_, bytecodeServer_) {
        if (gatewayAddress_ == address(0) || gasServiceAddress_ == address(0) || linkerRouterAddress_ == address(0))
            revert TokenServiceZeroAddress();
        gasService = IAxelarGasService(gasServiceAddress_);
        linkerRouter = ILinkerRouter(linkerRouterAddress_);
        expressCallHandler = IExpressCallHandler(expressCallHandlerAddress_);
        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
        lockUnlockImpl = implementations[uint256(TokenLinkerType.LOCK_UNLOCK)];
        mintBurnImpl = implementations[uint256(TokenLinkerType.MINT_BURN)];
        deployedImpl = implementations[uint256(TokenLinkerType.DEPLOYED)];
        gatewayImpl = implementations[uint256(TokenLinkerType.GATEWAY)];
    }

    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) return;
        _;
    }

    modifier onlyTokenLinker(bytes32 tokenLinkerId) {
        if (msg.sender != getTokenLinkerAddress(tokenLinkerId)) revert NotTokenLinker();
        _;
    }

    function gettokenLinkerId(address sender, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID, sender, salt));
    }

    function getImplementation(TokenLinkerType tokenLinkerType) external view returns (address impl) {
        if (tokenLinkerType == TokenLinkerType.LOCK_UNLOCK) {
            impl = lockUnlockImpl;
        } else if (tokenLinkerType == TokenLinkerType.MINT_BURN) {
            impl = mintBurnImpl;
        } else if (tokenLinkerType == TokenLinkerType.LOCK_UNLOCK) {
            impl = deployedImpl;
        } else if (tokenLinkerType == TokenLinkerType.LOCK_UNLOCK) {
            impl = gatewayImpl;
        }
    }

    /* EXTERNAL FUNCTIONS */

    function registerToken(bytes32 salt, TokenLinkerType tokenLinkerType, bytes calldata params) external returns (bytes32 tokenLinkerId) {
        address tokenAddress = abi.decode(params, (address));
        _validateOriginToken(tokenAddress);
        tokenLinkerId = gettokenLinkerId(msg.sender, salt);
        _registerToken(tokenLinkerId, tokenLinkerType, params);
    }

    function sendToken(
        bytes32 tokenLinkerId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable onlyTokenLinker(tokenLinkerId) {
        bytes memory payload = abi.encode(SEND_TOKEN_SELECTOR, tokenLinkerId, destinationAddress, amount);
        _callContract(destinationChain, payload, msg.value);
    }

    function sendTokenWithData(
        bytes32 tokenLinkerId,
        address sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable onlyTokenLinker(tokenLinkerId) {
        bytes memory sourceAddressBytes = sourceAddress.toBytes();
        bytes memory payload = abi.encode(
            SEND_TOKEN_WITH_DATA_SELECTOR,
            tokenLinkerId,
            destinationAddress,
            amount,
            chainName.toTrimmedString(),
            sourceAddressBytes,
            data
        );
        _callContract(destinationChain, payload, msg.value);
    }

    // UTILITY FUNCTIONS

    function _registerToken(
        bytes32 tokenLinkerId,
        TokenLinkerType tokenLinkerType,
        bytes calldata params
    ) internal returns (address tokenLinkerAddress) {
        tokenLinkerAddress = _deployTokenLinker(tokenLinkerId, tokenLinkerType, params);
        emit TokenRegistered(tokenLinkerId, tokenLinkerType, params, tokenLinkerAddress);
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

    /* EXECUTE */

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        uint256 selector = abi.decode(payload, (uint256));
        if (selector == SEND_TOKEN_SELECTOR) {
            _proccessSendTokenPayload(payload);
        } else if (selector == SEND_TOKEN_WITH_DATA_SELECTOR) {
            _proccessSendTokenWithDataPayload(payload);
        }
    }

    function _proccessSendTokenPayload(bytes calldata payload) internal {
        (, bytes32 tokenLinkerId, bytes memory destinationAddressBytes, uint256 amount, bytes32 sendHash) = abi.decode(
            payload,
            (uint256, bytes32, bytes, uint256, bytes32)
        );
        address tokenAddress = getTokenLinkerAddress(tokenLinkerId);
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenLinker(tokenAddress).giveToken(destinationAddress, amount);
        emit Receiving(tokenLinkerId, destinationAddress, amount, sendHash);
    }

    function _proccessSendTokenWithDataPayload(bytes calldata payload) internal {
        (
            ,
            bytes32 tokenLinkerId,
            bytes memory destinationAddressBytes,
            uint256 amount,
            string memory sourceChain,
            bytes memory sourceAddress,
            bytes memory data,
            bytes32 sendHash
        ) = abi.decode(payload, (uint256, bytes32, bytes, uint256, string, bytes, bytes, bytes32));
        address tokenAddress = getTokenLinkerAddress(tokenLinkerId);
        address destinationAddress = destinationAddressBytes.toAddress();
        ITokenLinker(tokenAddress).giveToken(destinationAddress, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool executionSuccessful, ) = destinationAddress.call(
            abi.encodeWithSelector(
                IInterchainTokenExecutable.exectuteWithInterchainToken.selector,
                tokenAddress,
                sourceChain,
                sourceAddress,
                amount,
                data
            )
        );
        emit ReceivingWithData(tokenLinkerId, sourceChain, destinationAddress, amount, sourceAddress, data, sendHash, executionSuccessful);
    }
}
