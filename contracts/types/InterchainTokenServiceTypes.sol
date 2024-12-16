// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum MessageType {
    INTERCHAIN_TRANSFER,
    DEPLOY_INTERCHAIN_TOKEN,
    DEPLOY_TOKEN_MANAGER,
    SEND_TO_HUB,
    RECEIVE_FROM_HUB,
    LINK_TOKEN,
    REGISTER_TOKEN_METADATA
}

struct InterchainTransfer {
    uint256 messageType;
    bytes32 tokenId;
    bytes sourceAddress;
    bytes destinationAddress;
    uint256 amount;
    bytes data;
}

struct DeployInterchainToken {
    uint256 messageType;
    bytes32 tokenId;
    string name;
    string symbol;
    uint8 decimals;
    bytes minter;
}

struct DeployTokenManager {
    uint256 messageType;
    bytes32 tokenId;
    uint256 tokenManagerType;
    bytes params;
}
