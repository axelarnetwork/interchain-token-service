// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenServiceVirtual } from './InterchainTokenServiceVirtual.sol';
import { ICallContract } from './interfaces/ICallContract.sol';

/**
 * @title The Interchain Token Service
 * @notice This contract is responsible for facilitating interchain token transfers.
 * It (mostly) does not handle tokens, but is responsible for the messaging that needs to occur for interchain transfers to happen.
 * @dev The only storage used in this contract is for Express calls.
 * Furthermore, no ether is intended to or should be sent to this contract except as part of deploy/interchainTransfer payable methods for gas payment.
 */
contract InterchainTokenServiceCallContract is InterchainTokenServiceVirtual {
    error CallContractFailed(bytes returnData);

    address public immutable callContract;

    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        address tokenManagerImplementation_,
        address tokenHandler_,
        address callContract_
    )
        InterchainTokenServiceVirtual(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            gasService_,
            interchainTokenFactory_,
            chainName_,
            tokenManagerImplementation_,
            tokenHandler_
        )
    {
        if (callContract_ == address(0)) revert ZeroAddress();

        callContract = callContract_;
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload
     * @param destinationChain The target chain where the contract will be called.
     * @param payload The data payload for the transaction.
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _callContract(
        string calldata destinationChain,
        bytes memory payload,
        ICallContract.MetadataVersion metadataVersion,
        uint256 gasValue
    ) internal override {
        string memory destinationAddress = trustedAddress(destinationChain);
        (bool success, bytes memory returnData) = callContract.delegatecall(
            abi.encodeWithSelector(
                ICallContract.callContract.selector,
                destinationChain,
                destinationAddress,
                payload,
                metadataVersion,
                gasValue
            )
        );

        if (!success) revert CallContractFailed(returnData);
    }

    /**
     * @notice Calls a contract on a specific destination chain with the given payload and gateway token
     * @param destinationChain The target chain where the contract will be called.
     * @param payload The data payload for the transaction.
     * @param symbol The gateway symbol of the token.
     * @param amount The amount of token transfered.
     * @param metadataVersion The metadata version
     * @param gasValue The amount of gas to be paid for the transaction.
     */
    function _callContractWithToken(
        string calldata destinationChain,
        bytes memory payload,
        string memory symbol,
        uint256 amount,
        ICallContract.MetadataVersion metadataVersion,
        uint256 gasValue
    ) internal override {
        string memory destinationAddress = trustedAddress(destinationChain);
        (bool success, bytes memory returnData) = callContract.delegatecall(
            abi.encodeWithSelector(
                ICallContract.callContractWithToken.selector,
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                metadataVersion,
                gasValue
            )
        );

        if (!success) revert CallContractFailed(returnData);
    }
}
