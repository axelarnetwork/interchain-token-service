# Solidity API

## TokenManagerDeployer

This contract is used to deploy new instances of the TokenManagerProxy contract.

### deployTokenManager

```solidity
function deployTokenManager(bytes32 tokenId, uint256 implementationType, bytes params) external payable returns (address tokenManager)
```

Deploys a new instance of the TokenManagerProxy contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | bytes32 | The unique identifier for the token |
| implementationType | uint256 | Token manager implementation type |
| params | bytes | Additional parameters used in the setup of the token manager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenManager | address | The address of the deployed tokenManager |

