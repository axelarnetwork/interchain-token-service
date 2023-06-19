// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

contract ExpressCallHandler is IExpressCallHandler {
    // solhint-disable no-inline-assembly
    // TODO: we can stick to {contract-name}-{purpose} for naming: prefix-express-give-token -> express-call-handler-send-token
    // uint256(keccak256('prefix-express-give-token')) - 1;
    // TODO: GIVE -> RECEIVE
    uint256 internal constant PREFIX_EXPRESS_GIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af86561a;
    // uint256(keccak256('prefix-express-give-token-with-data')) - 1;
    uint256 internal constant PREFIX_EXPRESS_GIVE_TOKEN_WITH_DATA = 0x3e607cc12a253b1d9f677a03d298ad869a90a8ba4bd0fb5739e7d79db7cdeaae;
    mapping(bytes32 => address) private expressGiveToken;
    mapping(bytes32 => address) private expressGiveTokenWithData;

    // TODO: _getExpressSendTokenSlot -> _getExpressReceiveSlot
    function _getExpressSendTokenSlot(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_GIVE_TOKEN, tokenId, destinationAddress, amount, sendHash)));
    }

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

    function _setExpressSendToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash,
        address expressCaller
    ) internal {
        uint256 slot = _getExpressSendTokenSlot(tokenId, destinationAddress, amount, sendHash);
        assembly {
            // TODO: check if slot has a non-zero value already, and revert
            sstore(slot, expressCaller)
        }
        // TODO: ExpressExecuted -> ExpressReceive, since not really executing arbitrary logic
        emit ExpressExecuted(tokenId, destinationAddress, amount, sendHash, expressCaller);
    }

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
            // TODO: same as above
            sstore(slot, expressCaller)
        }
        // TODO: ExpressExecutedWithData -> ExpressExecuted / ExpressExecutedWithReceive maybe?
        emit ExpressExecutedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash, expressCaller);
    }

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
