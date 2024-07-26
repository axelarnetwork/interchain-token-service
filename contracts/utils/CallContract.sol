// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

import { ICallContract } from '../interfaces/ICallContract.sol';

/**
 * @title CallContract contract
 * @notice This contract is used like a library to resolve metadata for the interchain token service
 */
contract CallContract is ICallContract {
    error UntrustedChain();
    error InvalidMetadataVersion(uint32 metadataVersion);

    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;

    constructor(address gateway_, address gasService_) {
        gateway = IAxelarGateway(gateway_);
        gasService = IAxelarGasService(gasService_);
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called.
     * @param destinationAddress The target address on the destination chain.
     * @param payload The data payload for the transaction.
     * @param metadataVersion The metadata version
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes memory payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable {
        if (bytes(destinationAddress).length == 0) revert UntrustedChain();

        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                gasService.payNativeGasForContractCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                gasService.payNativeGasForExpressCall{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload and gateway token
     * @param destinationChain The target chain where the contract will be called.
     * @param destinationAddress The target address on the destination chain.
     * @param payload The data payload for the transaction.
     * @param symbol The gateway symbol of the token.
     * @param amount The amount of token transfered.
     * @param metadataVersion The metadata version
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes memory payload,
        string memory symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable {
        if (bytes(destinationAddress).length == 0) revert UntrustedChain();

        if (gasValue > 0) {
            if (metadataVersion == MetadataVersion.CONTRACT_CALL) {
                gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else if (metadataVersion == MetadataVersion.EXPRESS_CALL) {
                gasService.payNativeGasForExpressCallWithToken{ value: gasValue }(
                    address(this),
                    destinationChain,
                    destinationAddress,
                    payload,
                    symbol,
                    amount, // solhint-disable-next-line avoid-tx-origin
                    tx.origin
                );
            } else {
                revert InvalidMetadataVersion(uint32(metadataVersion));
            }
        }

        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }
}
