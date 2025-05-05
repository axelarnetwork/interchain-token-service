// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
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
     * @param gasValue The amount of gas to be paid for the cross-chain message. If this is 0, then gas payment is skipped. `msg.value` must be at least gasValue.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        uint256 gasValue
    ) external payable override {
        if (gasValue > 0) {
            // slither-disable-next-line arbitrary-send-eth
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                // solhint-disable-next-line avoid-tx-origin
                tx.origin
            );
        }

        gateway.callContract(destinationChain, destinationAddress, payload);
    }
}
