// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

/**
 * @title ExpressCallHandler
 * @author Foivos Antoulinakis
 * @dev Integrates the interchain token service with the GMP express service by providing methods to handle express calls for
 * token transfers and token transfers with contract calls between chains. Implements the IExpressCallHandler interface.
 */
contract ExpressCallHandler is IExpressCallHandler {
    // solhint-disable no-inline-assembly
    // uint256(keccak256('prefix-express-give-token')) - 1;
    uint256 internal constant PREFIX_EXPRESS_GIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af86561a;
    // uint256(keccak256('prefix-express-give-token-with-data')) - 1;
    uint256 internal constant PREFIX_EXPRESS_GIVE_TOKEN_WITH_DATA = 0x3e607cc12a253b1d9f677a03d298ad869a90a8ba4bd0fb5739e7d79db7cdeaae;
    mapping(bytes32 => address) private expressGiveToken;
    mapping(bytes32 => address) private expressGiveTokenWithData;

    /**
     * @notice Calculates the unique slot for a given express token transfer.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param sendHash The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressSendTokenSlot(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_GIVE_TOKEN, tokenId, destinationAddress, amount, sendHash)));
    }

    /**
     * @notice Calculates the unique slot for a given token transfer with data
     * @param tokenId The ID of the token being sent
     * @param sourceChain The chain from which the token will be sent
     * @param sourceAddress The originating address of the token on the source chain
     * @param destinationAddress The address of the recipient on the destination chain
     * @param amount The amount of tokens to be sent
     * @param data The data associated with the token transfer
     * @param sendHash The unique hash for this token transfer
     * @return slot The calculated slot for this token transfer
     */
    function _getExpressSendTokenWithDataSlot(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 sendHash
    ) internal pure returns (uint256 slot) {
        slot = uint256(
            keccak256(
                abi.encode(
                    PREFIX_EXPRESS_GIVE_TOKEN_WITH_DATA,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationAddress,
                    amount,
                    data,
                    sendHash
                )
            )
        );
    }

    /**
     * @notice Stores the address of the express caller at the storage slot determined by _getExpressSendTokenSlot
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param sendHash The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressSendTokenSlot(tokenId, destinationAddress, amount, sendHash);
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressExecuted(tokenId, destinationAddress, amount, sendHash, expressCaller);
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
     * @param sendHash The unique hash for this token transfer
     * @param expressCaller The address of the express caller
     */
    function _setExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressSendTokenWithDataSlot(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
        assembly {
            sstore(slot, expressCaller)
        }
        emit ExpressExecutedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, expressCaller);
    }

    /**
     * @notice Gets the address of the express caller for a specific token transfer
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param sendHash The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressSendTokenSlot(tokenId, destinationAddress, amount, sendHash);
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
     * @param sendHash The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function getExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes calldata data,
        bytes32 sendHash
    ) public view returns (address expressCaller) {
        uint256 slot = _getExpressSendTokenWithDataSlot(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
        assembly {
            expressCaller := sload(slot)
        }
    }

    /**
     * @notice Removes the express caller from storage for a specific token transfer, if it exists.
     * @param tokenId The ID of the token being sent
     * @param destinationAddress The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param sendHash The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressSendTokenSlot(tokenId, destinationAddress, amount, sendHash);
        assembly {
            expressCaller := sload(slot)
        }
        if (expressCaller != address(0)) {
            assembly {
                sstore(slot, 0)
            }
            emit ExpressExecutionFulfilled(tokenId, destinationAddress, amount, sendHash, expressCaller);
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
     * @param sendHash The unique hash for this token transfer
     * @return expressCaller The address of the express caller for this token transfer
     */
    function _popExpressSendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressSendTokenWithDataSlot(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
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
                sendHash,
                expressCaller
            );
        }
    }
}
