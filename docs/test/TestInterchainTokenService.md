# Solidity API

## TestInterchainTokenService

### LatestMetadataVersionMismatch

```solidity
error LatestMetadataVersionMismatch(uint32 const, uint32 calculated)
```

### constructor

```solidity
constructor(address tokenManagerDeployer_, address interchainTokenDeployer_, address gateway_, address gasService_, address interchainTokenFactory_, string chainName_, address tokenManager_, address tokenHandler_, address gatewayCaller_) public
```

### setupTest

```solidity
function setupTest(bytes params) external
```

