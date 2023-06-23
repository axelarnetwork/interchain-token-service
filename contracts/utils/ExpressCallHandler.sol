// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
contract ExpressCallHandler is IExpressCallHandler {
    // solhint-disable no-inline-assembly
    // uint256(keccak256('prefix-express-give-token'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af865619;
    // uint256(keccak256('prefix-express-give-token-with-data'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA = 0x3e607cc12a253b1d9f677a03d298ad869a90a8ba4bd0fb5739e7d79db7cdeaad;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressReceiveTokenSlot(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, tokenId, destinationAddress, amount, commandId)));
    }

    /**
     * @notice Calculates the unique slot for a given token transfer with data
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressReceiveTokenWithDataSlot(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 commandId
    ) internal pure returns (uint256 slot) {
        slot = uint256(
            keccak256(
                abi.encode(
                    PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationAddress,
                    amount,
                    data,
                    commandId
                )
            )
        );
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }
        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();
        assembly {
            sstore(slot, expressCaller)
        }
        // TODO: ExpressReceived -> ExpressReceive, since not really executing arbitrary logic
        emit ExpressReceived(tokenId, destinationAddress, amount, commandId, expressCaller);
    }

    /**
     * @notice Stores the address of the express caller for a given token transfer with data at
     * the storage slot determined by _getExpressSendTokenWithDataSlot
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        address prevExpressCaller;
        assembly {
            prevExpressCaller := sload(slot)
        }
        if (prevExpressCaller != address(0)) revert AlreadyExpressCalled();
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressReceivedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer with data
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 commandId
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, commandId);
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionFulfilled(tokenId, destinationAddress, amount, commandId, expressCaller);
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer with data, if it exists.
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param commandId The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 commandId
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(
            tokenId,
            sourceChain,
            sourceAddress,
            destinationAddress,
            amount,
            data,
            commandId
        );
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionWithDataFulfilled(
                tokenId,
                sourceChain,
                sourceAddress,
                destinationAddress,
                amount,
                data,
                commandId,
                expressCaller
            );
        }
    }
}
