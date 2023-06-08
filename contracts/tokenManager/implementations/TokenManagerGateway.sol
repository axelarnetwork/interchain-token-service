// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManagerAddressStorage } from './TokenManagerAddressStorage.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

contract TokenManagerGateway is TokenManagerAddressStorage {
    error NotGatewayToken();

    string public gatewaySymbol;

    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManagerAddressStorage(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}

    function requiresApproval() external pure returns (bool) {
        return true;
    }

    function _setup(bytes calldata params) internal override {
        //the first argument is reserved for the admin.
        string memory symbol;
        (, symbol) = abi.decode(params, (bytes, string));
        gatewaySymbol = symbol;
        IAxelarGateway gateway = interchainTokenService.gateway();
        address tokenAddress_ = gateway.tokenAddresses(symbol);
        if (tokenAddress_ == address(0)) revert NotGatewayToken();
        _setTokenAddress(tokenAddress_);
    }

    function _takeToken(address from, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress();

        // Use SafeERC20 from gmp sdk
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(interchainTokenService), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert TakeTokenFailed();

        return amount;
    }

    function _giveToken(address to, uint256 amount) internal override returns (uint256) {
        address token = tokenAddress();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || token.code.length == 0) revert GiveTokenFailed();
        return amount;
    }

    function _transmitSendToken(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) internal override {
        interchainTokenService.transmitSendTokenWithToken{ value: msg.value }(
            _getTokenId(),
            gatewaySymbol,
            sender,
            destinationChain,
            destinationAddress,
            amount
        );
    }

    function _transmitSendTokenWithData(
        address sender,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) internal override {
        interchainTokenService.transmitSendTokenWithDataWithToken{ value: msg.value }(
            _getTokenId(),
            gatewaySymbol,
            sender,
            destinationChain,
            destinationAddress,
            amount,
            data
        );
    }

    // This will automatically happen on deployment once deployment is complete (the service will run some checks to make sure this can happen only once)
    function gatewayApprove() external {
        interchainTokenService.approveGateway(_getTokenId(), tokenAddress());
    }
}
