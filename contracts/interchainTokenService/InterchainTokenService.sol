// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

import { EternalStorage } from '@axelar-network/axelar-cgp-solidity/contracts/EternalStorage.sol';

import { IInterchainTokenService } from '../interfaces/IInterchainTokenService.sol';
import { ITokenDeployer } from '../interfaces/ITokenDeployer.sol';
import { ILinkerRouter } from '../interfaces/ILinkerRouter.sol';
import { IERC20BurnableMintable } from '../interfaces/IERC20BurnableMintable.sol';
import { IERC20Named } from '../interfaces/IERC20Named.sol';
import { IInterTokenExecutable } from '../interfaces/IInterTokenExecutable.sol';

import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

contract InterchainTokenService is IInterchainTokenService, AxelarExecutable, EternalStorage, Upgradable {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using LinkedTokenData for bytes32;

    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    ITokenDeployer public immutable tokenDeployer;

    bytes32 internal constant PREFIX_TOKEN_DATA = keccak256('itl-token-data');
    bytes32 internal constant PREFIX_ORIGINAL_CHAIN = keccak256('itl-original-chain');
    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('itl-token-id');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('itl-token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('itl-token-mint-amount');
    // keccak256('interchain-token-service')-1
    bytes32 public constant contractId = 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;

    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    constructor(
        address gatewayAddress_,
        address gasServiceAddress_,
        address linkerRouterAddress_,
        address tokenDeployerAddress_,
        string memory chainName_
    ) AxelarExecutable(gatewayAddress_) {
        if (gatewayAddress_ == address(0) || gasServiceAddress_ == address(0) || linkerRouterAddress_ == address(0))
            revert TokenServiceZeroAddress();
        gasService = IAxelarGasService(gasServiceAddress_);
        linkerRouter = ILinkerRouter(linkerRouterAddress_);
        tokenDeployer = ITokenDeployer(tokenDeployerAddress_);
        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    /* KEY GETTERS */

    function _getTokenDataKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_DATA, tokenId));
    }

    function _getOriginalChainKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_ORIGINAL_CHAIN, tokenId));
    }

    function _getTokenIdKey(address tokenAddress) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_ID, tokenAddress));
    }

    function _getTokenMintLimitKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_MINT_LIMIT, tokenId));
    }

    function _getTokenMintAmountKey(bytes32 tokenId, uint256 epoch) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_MINT_AMOUNT, tokenId, epoch));
    }

    /* GETTERS AND SETTERS*/

    function getTokenData(bytes32 tokenId) public view returns (bytes32 tokenData) {
        tokenData = bytes32(getUint(_getTokenDataKey(tokenId)));
    }

    function _setTokenData(bytes32 tokenId, bytes32 tokenData) internal {
        _setUint(_getTokenDataKey(tokenId), uint256(tokenData));
    }

    function getOriginalChain(bytes32 tokenId) public view returns (string memory originalChain) {
        bytes32 originalChainBytes = bytes32(getUint(_getOriginalChainKey(tokenId)));
        originalChain = originalChainBytes.toTrimmedString();
    }

    function _setOriginalChain(bytes32 tokenId, string memory originalChain) internal {
        _setUint(_getOriginalChainKey(tokenId), uint256(originalChain.toBytes32()));
    }

    function getTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = bytes32(getUint(_getTokenIdKey(tokenAddress)));
    }

    function _setTokenId(address tokenAddress, bytes32 tokenId) internal {
        _setUint(_getTokenIdKey(tokenAddress), uint256(tokenId));
    }

    function getTokenMintLimit(bytes32 tokenId) public view returns (uint256 mintLimit) {
        mintLimit = getUint(_getTokenMintLimitKey(tokenId));
    }

    function _setTokenMintLimit(bytes32 tokenId, uint256 mintLimit) internal {
        _setUint(_getTokenMintLimitKey(tokenId), mintLimit);
    }

    function getTokenMintAmount(bytes32 tokenId) public view returns (uint256 amount) {
        amount = getUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours));
    }

    function _setTokenMintAmount(bytes32 tokenId, uint256 amount) internal {
        uint256 limit = getTokenMintLimit(tokenId);
        if (limit > 0 && amount > limit) revert ExceedMintLimit(tokenId);

        _setUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours), amount);
    }

    function getTokenAddress(bytes32 tokenId) public view returns (address) {
        return getTokenData(tokenId).getAddress();
    }

    function getOriginTokenId(address tokenAddress) public view returns (bytes32) {
        return keccak256(abi.encode(chainNameHash, tokenAddress));
    }

    function getDeploymentSalt(address sender, bytes32 salt) public pure returns (bytes32 deploymentSalt) {
        deploymentSalt = keccak256(abi.encode(sender, salt));
    }

    function getDeploymentAddress(address sender, bytes32 salt) public view returns (address deployment) {
        salt = getDeploymentSalt(sender, salt);
        deployment = tokenDeployer.getDeploymentAddress(salt);
    }

    /* EXTERNAL FUNCTIONS */

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable {
        salt = getDeploymentSalt(msg.sender, salt);
        _deployToken(tokenName, tokenSymbol, decimals, owner, salt);
        // TODO: Implement remote deployments.
    }

    function registerOriginToken(address tokenAddress) external returns (bytes32 tokenId) {
        //TODO: Implement.
    }

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId) {
        //TODO: Implement.
    }

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable {
        //TODO: Implement.
    }

    function sendToken(bytes32 tokenId, string memory destinationChain, bytes memory to, uint256 amount) external payable {
        //TODO: Implement.
    }

    function callContractWithInterToken(
        bytes32 tokenId,
        string memory destinationChain,
        bytes memory to,
        uint256 amount,
        bytes calldata data
    ) external payable {
        //TODO: Implement.
    }

    function registerOriginGatewayToken(string calldata symbol) external returns (bytes32 tokenId) {
        //TODO: Implement.
    }

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external {
        //TODO: Implement.
    }

    // These two are meant to be called by tokens to have this service facilitate the token transfers for them.
    function sendSelf(address from, string memory destinationChain, bytes memory to, uint256 amount) external payable {
        //TODO: Implement.
    }

    function callContractWithSelf(
        address from,
        string memory destinationChain,
        bytes memory to,
        uint256 amount,
        bytes calldata data
    ) external payable {
        //TODO: Implement.
    }

    // UTILITY FUNCTIONS
    function _transfer(address tokenAddress, address destinationaddress, uint256 amount) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transfer.selector, destinationaddress, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }

    function _transferFrom(address tokenAddress, address from, uint256 amount) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFromFailed();
    }

    function _mint(address tokenAddress, address destinationaddress, uint256 amount) internal {
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, destinationaddress, amount));

        if (!success || tokenAddress.code.length == 0) revert MintFailed();
    }

    function _burn(address tokenAddress, address from, uint256 amount) internal {
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintable.burnFrom.selector, from, amount));

        if (!success || tokenAddress.code.length == 0) revert BurnFailed();
    }

    function _giveToken(bytes32 tokenId, address destinationaddress, uint256 amount) internal {
        _setTokenMintAmount(tokenId, getTokenMintAmount(tokenId) + amount);

        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();

        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transfer(tokenAddress, destinationaddress, amount);
        } else {
            _mint(tokenAddress, destinationaddress, amount);
        }
    }

    function _takeToken(bytes32 tokenId, address from, uint256 amount) internal {
        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transferFrom(tokenAddress, from, amount);
        } else {
            _burn(tokenAddress, from, amount);
        }
    }

    function _giveTokenWithData(
        bytes32 tokenId,
        address destinationaddress,
        uint256 amount,
        string calldata sourceChain,
        bytes memory sourceAddress,
        bytes memory data
    ) internal {
        _setTokenMintAmount(tokenId, getTokenMintAmount(tokenId) + amount);

        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transfer(tokenAddress, destinationaddress, amount);
        } else {
            _mint(tokenAddress, destinationaddress, amount);
        }
        IInterTokenExecutable(destinationaddress).exectuteWithInterToken(tokenAddress, sourceChain, sourceAddress, amount, data);
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

    function _callContractWithToken(string memory destinationChain, bytes32 tokenData, uint256 amount, bytes memory payload) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        uint256 gasValue = msg.value;
        string memory symbol = tokenData.getSymbol();
        if (gasValue > 0) {
            gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                msg.sender
            );
        }
        IERC20Named(tokenData.getAddress()).approve(address(gateway), amount);
        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }

    function _deployToken(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals,
        address owner,
        bytes32 salt
    ) internal returns (address tokenAddress) {
        (bool success, bytes memory data) = address(tokenDeployer).delegatecall(
            abi.encodeWithSelector(tokenDeployer.deployToken.selector, tokenName, tokenSymbol, decimals, owner, salt)
        );
        if (!success) revert TokenDeploymentFailed();
        tokenAddress = abi.decode(data, (address));

        emit TokenDeployed(tokenAddress, tokenName, tokenSymbol, decimals, owner);
    }
}
