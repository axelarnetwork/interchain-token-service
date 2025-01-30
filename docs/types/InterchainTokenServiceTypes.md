# Solidity API

## MessageType

```solidity
enum MessageType {
  INTERCHAIN_TRANSFER,
  DEPLOY_INTERCHAIN_TOKEN,
  DEPLOY_TOKEN_MANAGER,
  SEND_TO_HUB,
  RECEIVE_FROM_HUB
}
```

## InterchainTransfer

```solidity
struct InterchainTransfer {
  uint256 messageType;
  bytes32 tokenId;
  bytes sourceAddress;
  bytes destinationAddress;
  uint256 amount;
  bytes data;
}
```

## DeployInterchainToken

```solidity
struct DeployInterchainToken {
  uint256 messageType;
  bytes32 tokenId;
  string name;
  string symbol;
  uint8 decimals;
  bytes minter;
}
```

## DeployTokenManager

```solidity
struct DeployTokenManager {
  uint256 messageType;
  bytes32 tokenId;
  uint256 tokenManagerType;
  bytes params;
}
```

