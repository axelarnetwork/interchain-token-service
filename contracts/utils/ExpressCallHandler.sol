// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IExpressCallHandler } from '../interfaces/IExpressCallHandler.sol';

contract ExpressCallHandler is IExpressCallHandler {
    // solhint-disable no-inline-assembly
    // TODO: we can stick to {contract-name}-{purpose} for naming: prefix-express-give-token -> express-call-handler-send-token
    // uint256(keccak256('prefix-express-give-token'));
    // TODO: GIVE -> RECEIVE
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN = 0x67c7b41c1cb0375e36084c4ec399d005168e83425fa471b9224f6115af865619;
    // uint256(keccak256('prefix-express-give-token-with-data'));
    uint256 internal constant PREFIX_EXPRESS_RECEIVE_TOKEN_WITH_DATA = 0x3e607cc12a253b1d9f677a03d298ad869a90a8ba4bd0fb5739e7d79db7cdeaad;
    mapping(bytes32 => address) private expressGiveToken;
    mapping(bytes32 => address) private expressGiveTokenWithData;

    function _getExpressReceiveTokenSlot(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 commandId
    ) internal pure returns (uint256 slot) {
        slot = uint256(keccak256(abi.encode(PREFIX_EXPRESS_RECEIVE_TOKEN, tokenId, destinationAddress, amount, commandId)));
    }

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
            // TODO: same as above
            sstore(slot, expressCaller)
        }
        // TODO: ExpressReceivedWithData -> ExpressReceived / ExpressReceivedWithReceive maybe?
        emit ExpressReceivedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, commandId, expressCaller);
    }

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

    function _popExpressReceiveToken(
        bytes32 tokenId,
        address destinationAddress,
        uint256 amount,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenSlot(tokenId, destinationAddress, amount, sendHash);
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

    function _popExpressReceiveTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes memory data,
        bytes32 sendHash
    ) internal returns (address expressCaller) {
        uint256 slot = _getExpressReceiveTokenWithDataSlot(tokenId, sourceChain, sourceAddress, destinationAddress, amount, data, sendHash);
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
