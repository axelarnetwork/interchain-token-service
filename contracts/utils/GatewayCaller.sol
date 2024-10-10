// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGatewayWithToken } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGatewayWithToken.sol';
import { IGatewayCaller } from '../interfaces/IGatewayCaller.sol';

/**
 * @title GatewayCaller contract
 * @dev This contract is used to handle cross-chain ITS calls via the Axelar gateway.
 */
contract GatewayCaller is IGatewayCaller {
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;

    /**
     * @dev Constructor to initialize the GatewayCaller contract
     * @param gateway_ The address of the AxelarGateway contract
     * @param gasService_ The address of the AxelarGasService contract
     */
    constructor(address gateway_, address gasService_) {
        gateway = IAxelarGateway(gateway_);
        gasService = IAxelarGasService(gasService_);
    }

    /**
     * @dev Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called
     * @param destinationAddress The address of the contract to be called on the destination chain
     * @param payload The data payload for the transaction
     * @param metadataVersion The version of metadata to be used
     * @param gasValue The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable override {
        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                // slither-disable-next-line arbitrary-send-eth
                gasService.payNativeGasForContractCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                // slither-disable-next-line arbitrary-send-eth
                gasService.payNativeGasForExpressCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @dev Calls a contract on a specific destination chain with the given payload and token
     * @param destinationChain The target chain where the contract will be called
     * @param destinationAddress The address of the contract to be called on the destination chain
     * @param payload The data payload for the transaction
     * @param symbol The symbol of the token to be sent
     * @param amount The amount of tokens to be sent
     * @param metadataVersion The version of metadata to be used
     * @param gasValue The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue.
     */
    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable override {
        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                // slither-disable-next-line arbitrary-send-eth
                gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount,
                    // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                // slither-disable-next-line arbitrary-send-eth
                gasService.payNativeGasForExpressCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount,
                    // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        IAxelarGatewayWithToken(address(gateway)).callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }
}
