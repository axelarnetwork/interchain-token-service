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
import { IInterchainTokenExecutable } from '../interfaces/IInterchainTokenExecutable.sol';

import { AddressBytesUtils } from '../libraries/AddressBytesUtils.sol';
import { LinkedTokenData } from '../libraries/LinkedTokenData.sol';
import { StringToBytes32, Bytes32ToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Bytes32String.sol';

contract InterchainTokenService is IInterchainTokenService, AxelarExecutable, EternalStorage, Upgradable {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;
    using LinkedTokenData for bytes32;
    using AddressBytesUtils for bytes;

    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    ITokenDeployer public immutable tokenDeployer;

    bytes32 internal constant PREFIX_TOKEN_DATA = keccak256('itl-token-data');
    bytes32 internal constant PREFIX_ORIGINAL_CHAIN = keccak256('itl-original-chain');
    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('itl-token-id');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('itl-token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('itl-token-mint-amount');
    bytes32 internal constant PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID = keccak256('itl-custom-interchain-token-id');
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

    modifier onlyRemoteService(string calldata sourceChain, string calldata sourceAddress) {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) return;
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

    function isOriginToken(bytes32 tokenId) external view returns (bool) {
        bytes32 tokenData = getTokenData(tokenId);
        if (tokenData == bytes32(0)) revert NotRegistered(tokenId);

        return tokenData.isOrigin();
    }

    function isGatewayToken(bytes32 tokenId) external view returns (bool) {
        bytes32 tokenData = getTokenData(tokenId);
        if (tokenData == bytes32(0)) revert NotRegistered(tokenId);

        return tokenData.isGateway();
    }

    function getGatewayTokenSymbol(bytes32 tokenId) external view returns (string memory symbol) {
        bytes32 tokenData = getTokenData(tokenId);
        if (!tokenData.isGateway()) revert NotGatewayToken();

        symbol = tokenData.getSymbol();
    }

    function isRemoteGatewayToken(bytes32 tokenId) external view returns (bool) {
        bytes32 tokenData = getTokenData(tokenId);
        if (tokenData == bytes32(0)) revert NotRegistered(tokenId);

        return tokenData.isRemoteGateway();
    }

    function isCustomInterchainToken(bytes32 tokenId) external view returns (bool) {
        bytes32 tokenData = getTokenData(tokenId);
        if (tokenData == bytes32(0)) revert NotRegistered(tokenId);

        if (tokenData.isOrigin()) return false;

        bytes32 originalChainBytes = bytes32(getUint(_getOriginalChainKey(tokenId)));
        return originalChainBytes == bytes32(0);
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

    function getTokenMintAmount(bytes32 tokenId) internal view returns (uint256 amount) {
        // solhint-disable-next-line not-rely-on-time
        amount = getUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours));
    }

    function _setTokenMintAmount(bytes32 tokenId, uint256 amount) internal {
        uint256 limit = getTokenMintLimit(tokenId);
        if (limit > 0 && amount > limit) revert ExceedMintLimit(tokenId);
        // solhint-disable-next-line not-rely-on-time
        _setUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours), amount);
    }

    function getTokenAddress(bytes32 tokenId) public view returns (address) {
        return getTokenData(tokenId).getAddress();
    }

    function getOriginTokenId(address tokenAddress) public view returns (bytes32) {
        return keccak256(abi.encode(chainNameHash, tokenAddress));
    }

    function getInterchainTokenId(address sender, bytes32 salt) public view returns (bytes32) {
        return keccak256(abi.encode(chainNameHash, sender, salt));
    }

    function getCustomInterchainTokenId(address tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encode(PREFIX_CUSTOM_INTERCHAIN_TOKEN_ID, tokenAddress));
    }

    function getDeploymentAddress(address sender, bytes32 salt) public view returns (address deployment) {
        salt = getInterchainTokenId(sender, salt);
        deployment = tokenDeployer.getDeploymentAddress(address(this), salt);
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
    ) external payable returns (bytes32 tokenId) {
        tokenId = getInterchainTokenId(msg.sender, salt);
        address tokenAddress = _deployToken(tokenName, tokenSymbol, decimals, owner, tokenId);
        bytes32 tokenData = _registerToken(tokenAddress, tokenId, true);
        string memory symbol = _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
        if (gateway.tokenAddresses(symbol) == tokenAddress) revert GatewayToken();
    }

    function registerOriginToken(address tokenAddress) external returns (bytes32 tokenId) {
        _validateOriginToken(tokenAddress);
        tokenId = getOriginTokenId(tokenAddress);
        _registerToken(tokenAddress, tokenId, true);
    }

    // Tokens have to register themselves (typically in the constructor).
    // This is done to prevent malicious actors from registering tokens as Interchain tokens which would lock them from ever being registered as origin tokens in the future.
    function registerSelfAsInterchainToken() external returns (bytes32 tokenId) {
        address tokenAddress = msg.sender;
        tokenId = getCustomInterchainTokenId(tokenAddress);
        _registerToken(tokenAddress, tokenId, false);
    }

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId) {
        bytes32 tokenData;
        tokenId = getOriginTokenId(tokenAddress);
        tokenData = _registerToken(tokenAddress, tokenId, true);
        string memory symbol = _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
        if (gateway.tokenAddresses(symbol) == tokenAddress) revert GatewayToken();
    }

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable {
        bytes32 tokenData = getTokenData(tokenId);
        if (!tokenData.isOrigin()) revert NotOriginToken();
        _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
    }

    function sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata to, uint256 amount) external payable {
        _transferOrBurnFrom(tokenId, msg.sender, amount);
        _sendToken(tokenId, destinationChain, to, amount);
    }

    function callContractWithInterchainToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata to,
        uint256 amount,
        bytes calldata data
    ) external payable {
        _transferOrBurnFrom(tokenId, msg.sender, amount);
        _sendTokenWithData(tokenId, chainName.toTrimmedString(), AddressBytesUtils.toBytes(msg.sender), destinationChain, to, amount, data);
    }

    function registerOriginGatewayToken(string calldata symbol) external onlyOwner returns (bytes32 tokenId) {
        address tokenAddress = gateway.tokenAddresses(symbol);
        if (tokenAddress == address(0)) revert NotGatewayToken();
        tokenId = getOriginTokenId(tokenAddress);
        _setTokenData(tokenId, LinkedTokenData.createGatewayTokenData(tokenAddress, true, symbol));
        _setTokenId(tokenAddress, tokenId);
        emit TokenRegistered(tokenId, tokenAddress, true, true, false);
    }

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external onlyOwner {
        address tokenAddress = gateway.tokenAddresses(symbol);
        if (tokenAddress == address(0)) revert NotGatewayToken();
        _setTokenData(tokenId, LinkedTokenData.createGatewayTokenData(tokenAddress, false, symbol));
        _setTokenId(tokenAddress, tokenId);
        _setOriginalChain(tokenId, origin);
        emit TokenRegistered(tokenId, tokenAddress, false, true, false);
    }

    // These two are meant to be called by tokens to have this service facilitate the token transfers for them.
    function sendSelf(address from, string calldata destinationChain, bytes calldata to, uint256 amount) external payable {
        bytes32 tokenId = getTokenId(msg.sender);
        _transferOrBurnFrom(tokenId, from, amount);
        (tokenId, from, amount);
        _sendToken(tokenId, destinationChain, to, amount);
    }

    function callContractWithSelf(
        address from,
        string calldata destinationChain,
        bytes calldata to,
        uint256 amount,
        bytes calldata data
    ) external payable {
        bytes32 tokenId = getTokenId(msg.sender);
        _transferOrBurnFrom(tokenId, from, amount);
        _sendTokenWithData(tokenId, chainName.toTrimmedString(), AddressBytesUtils.toBytes(msg.sender), destinationChain, to, amount, data);
    }

    /* ONLY SELF FUNCTIONS */

    function selfDeployToken(
        bytes32 tokenId,
        string memory origin,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        bool isGateway
    ) public onlySelf {
        {
            bytes32 tokenData = getTokenData(tokenId);
            if (tokenData != bytes32(0)) {
                if (isGateway && !tokenData.isGateway()) {
                    _setTokenData(tokenId, LinkedTokenData.createRemoteGatewayTokenData(tokenData.getAddress()));
                    return;
                }
                revert AlreadyRegistered();
            }
        }
        address tokenAddress = _deployToken(tokenName, tokenSymbol, decimals, address(this), tokenId);
        if (isGateway) {
            _setTokenData(tokenId, LinkedTokenData.createRemoteGatewayTokenData(tokenAddress));
        } else {
            _setTokenData(tokenId, LinkedTokenData.createTokenData(tokenAddress, false));
        }
        _setTokenId(tokenAddress, tokenId);
        _setOriginalChain(tokenId, origin);
        emit TokenRegistered(tokenId, tokenAddress, false, false, isGateway);
    }

    function selfTransferOrMint(bytes32 tokenId, bytes calldata destinationAddress, uint256 amount) public onlySelf {
        _transferOrMint(tokenId, AddressBytesUtils.toAddress(destinationAddress), amount);
    }

    function selfTransferOrMintWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) public onlySelf {
        _transferOrMintWithData(tokenId, AddressBytesUtils.toAddress(destinationAddress), amount, sourceChain, sourceAddress, data);
    }

    function selfSendToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) public onlySelf {
        _sendToken(tokenId, destinationChain, destinationAddress, amount);
    }

    function selfSendTokenWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) public onlySelf {
        _sendTokenWithData(tokenId, sourceChain, sourceAddress, destinationChain, destinationAddress, amount, data);
    }

    // UTILITY FUNCTIONS
    function _transfer(address tokenAddress, address destinationaddress, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transfer.selector, destinationaddress, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }

    function _transferFrom(address tokenAddress, address from, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFromFailed();
    }

    function _mint(address tokenAddress, address destinationaddress, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintable.mint.selector, destinationaddress, amount));

        if (!success || tokenAddress.code.length == 0) revert MintFailed();
    }

    function _burn(address tokenAddress, address from, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintable.burnFrom.selector, from, amount));

        if (!success || tokenAddress.code.length == 0) revert BurnFailed();
    }

    function _transferOrMint(bytes32 tokenId, address destinationaddress, uint256 amount) internal returns (address tokenAddress) {
        _setTokenMintAmount(tokenId, getTokenMintAmount(tokenId) + amount);

        bytes32 tokenData = getTokenData(tokenId);
        tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transfer(tokenAddress, destinationaddress, amount);
        } else {
            _mint(tokenAddress, destinationaddress, amount);
        }
    }

    function _transferOrBurnFrom(bytes32 tokenId, address from, uint256 amount) internal {
        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transferFrom(tokenAddress, from, amount);
        } else {
            _burn(tokenAddress, from, amount);
        }
    }

    function _transferOrMintWithData(
        bytes32 tokenId,
        address destinationaddress,
        uint256 amount,
        string calldata sourceChain,
        bytes memory sourceAddress,
        bytes memory data
    ) internal {
        address tokenAddress = _transferOrMint(tokenId, destinationaddress, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool executionSuccessful, ) = destinationaddress.call(
            abi.encodeWithSelector(
                IInterchainTokenExecutable.exectuteWithInterchainToken.selector,
                tokenAddress,
                sourceChain,
                sourceAddress,
                amount,
                data
            )
        );
        emit ReceivingWithData(sourceChain, destinationaddress, amount, sourceAddress, data, executionSuccessful);
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
        bytes32 tokenId
    ) internal returns (address tokenAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(tokenDeployer).delegatecall(
            abi.encodeWithSelector(tokenDeployer.deployToken.selector, tokenName, tokenSymbol, decimals, owner, tokenId)
        );
        if (!success) revert TokenDeploymentFailed();
        tokenAddress = abi.decode(data, (address));

        emit TokenDeployed(tokenAddress, tokenName, tokenSymbol, decimals, owner);
    }

    function _registerToken(address tokenAddress, bytes32 tokenId, bool origin) internal returns (bytes32 tokenData) {
        if (getTokenId(tokenAddress) != bytes32(0)) revert AlreadyRegistered();
        if (getTokenData(tokenId) != bytes32(0)) revert AlreadyRegistered();
        tokenData = LinkedTokenData.createTokenData(tokenAddress, origin);
        _setTokenData(tokenId, tokenData);
        _setTokenId(tokenAddress, tokenId);
        emit TokenRegistered(tokenId, tokenAddress, origin, false, false);
    }

    function _validateOriginToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    /* EXECUTE AND EXECUTE WITH TOKEN */

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(payload);
        if (!success) revert ExecutionFailed();
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata /*symbol*/,
        uint256 /*amount*/
    ) internal override onlyRemoteService(sourceChain, sourceAddress) {
        _execute(sourceChain, sourceAddress, payload);
    }

    function _deployRemoteTokens(
        string[] calldata destinationChains,
        uint256[] calldata gasValues,
        bytes32 tokenId,
        bytes32 tokenData
    ) internal returns (string memory) {
        (string memory name, string memory symbol, uint8 decimals) = _validateOriginToken(tokenData.getAddress());
        uint256 length = destinationChains.length;
        if (gasValues.length != length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            uint256 gasValue = gasValues[i];
            if (tokenData.isGateway() && linkerRouter.supportedByGateway(destinationChains[i])) revert GatewayToken();
            bytes memory payload = abi.encodeWithSelector(
                this.selfDeployToken.selector,
                tokenId,
                chainName.toTrimmedString(),
                name,
                symbol,
                decimals,
                tokenData.isGateway()
            );
            _callContract(destinationChains[i], payload, gasValue);
            emit RemoteTokenRegisterInitialized(tokenId, destinationChains[i], gasValue);
        }
        return symbol;
    }

    function _sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata destinationaddress, uint256 amount) internal {
        bytes32 tokenData = getTokenData(tokenId);
        if (tokenData == bytes32(0)) revert NotRegistered(tokenId);
        bytes memory payload;

        if (tokenData.isGateway()) {
            if (linkerRouter.supportedByGateway(destinationChain)) {
                payload = abi.encodeWithSelector(this.selfTransferOrMint.selector, tokenId, destinationaddress, amount);
                _callContractWithToken(destinationChain, tokenData, amount, payload);
            } else if (tokenData.isOrigin()) {
                payload = abi.encodeWithSelector(this.selfTransferOrMint.selector, tokenId, destinationaddress, amount);
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(this.selfSendToken.selector, tokenId, destinationChain, destinationaddress, amount);
                _callContractWithToken(getOriginalChain(tokenId), tokenData, amount, payload);
            }
        } else if (tokenData.isRemoteGateway()) {
            if (keccak256(bytes(destinationChain)) == keccak256(bytes(getOriginalChain(tokenId)))) {
                payload = abi.encodeWithSelector(this.selfTransferOrMint.selector, tokenId, destinationaddress, amount);
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(this.selfSendToken.selector, tokenId, destinationChain, destinationaddress, amount);
                _callContract(getOriginalChain(tokenId), payload, msg.value);
            }
        } else {
            payload = abi.encodeWithSelector(this.selfTransferOrMint.selector, tokenId, destinationaddress, amount);
            _callContract(destinationChain, payload, msg.value);
        }
        emit Sending(destinationChain, destinationaddress, amount);
    }

    function _sendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationaddress,
        uint256 amount,
        bytes calldata data
    ) internal {
        bytes32 tokenData = getTokenData(tokenId);
        bytes memory payload;

        if (tokenData.isGateway()) {
            if (linkerRouter.supportedByGateway(destinationChain)) {
                payload = abi.encodeWithSelector(
                    this.selfTransferOrMintWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContractWithToken(destinationChain, tokenData, amount, payload);
            } else if (tokenData.isOrigin()) {
                payload = abi.encodeWithSelector(
                    this.selfTransferOrMintWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(
                    this.selfSendTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationChain,
                    destinationaddress,
                    amount,
                    data
                );
                _callContractWithToken(getOriginalChain(tokenId), tokenData, amount, payload);
            }
        } else if (tokenData.isRemoteGateway()) {
            if (keccak256(bytes(destinationChain)) == keccak256(bytes(getOriginalChain(tokenId)))) {
                payload = abi.encodeWithSelector(
                    this.selfTransferOrMintWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(
                    this.selfSendTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationChain,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(getOriginalChain(tokenId), payload, msg.value);
            }
        } else {
            payload = abi.encodeWithSelector(
                this.selfTransferOrMintWithData.selector,
                tokenId,
                sourceChain,
                sourceAddress,
                destinationaddress,
                amount,
                data
            );
            _callContract(destinationChain, payload, msg.value);
        }
        emit SendingWithData(destinationChain, destinationaddress, amount, msg.sender, data);
    }
}
