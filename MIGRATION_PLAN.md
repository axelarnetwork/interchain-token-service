# Interchain Token Service Modularization Migration Plan

## Overview

This document outlines the plan to refactor the Interchain Token Service (ITS) into a modular architecture that supports multiple chain types (EVM, Hedera, Hyperliquid) while maintaining a single codebase on the main branch.

## Current State Analysis

### Existing Structure
- **interchain-token-service-axelar**: Standard EVM implementation (v2.2.0)
- **interchain-token-service**: Hedera fork with HTS integration (v2.1.0)
- **Hyperliquid integration**: Already modularized in axelar version

### Key Differences
1. **Token Address Resolution**:
   - EVM: Deterministic addresses via CREATE3
   - Hedera: Non-deterministic addresses, requires registry

2. **Token Creation**:
   - EVM: Standard ERC20 deployment
   - Hedera: HTS precompile with WHBAR fees

3. **Token Operations**:
   - EVM: Standard ERC20 functions
   - Hedera: HTS precompile calls

## Refactoring Strategy

### 1. Abstract Base Contract Pattern

Following OpenZeppelin's approach, we'll create abstract base contracts with virtual functions:

```
AbstractInterchainTokenService
├── EVMInterchainTokenService
├── HederaInterchainTokenService
└── HyperliquidInterchainTokenService
```

### 2. Virtual Functions for Chain-Specific Operations

#### Core Virtual Functions:
- `_deployInterchainToken()` - Token deployment logic
- `_getTokenAddress()` - Address resolution
- `_getTokenCreationPrice()` - Pricing logic
- `_transferToken()` - Transfer mechanisms
- `_mintToken()` - Minting mechanisms
- `_burnToken()` - Burning mechanisms

### 3. Implementation Hierarchy

```
AbstractInterchainTokenService (Base)
├── EVMInterchainTokenService (Standard EVM)
│   └── HyperliquidInterchainTokenService (EVM + Hyperliquid features)
└── HederaInterchainTokenService (Hedera-specific)
```

## Migration Steps

### Phase 1: Create Abstract Base Contract
- [x] Create `AbstractInterchainTokenService.sol`
- [x] Define virtual functions for chain-specific operations
- [x] Implement common ITS functionality

### Phase 2: Implement Chain-Specific Versions
- [x] Create `EVMInterchainTokenService.sol`
- [x] Create `HederaInterchainTokenService.sol`
- [x] Update `HyperliquidInterchainTokenService.sol`

### Phase 3: Create Factory Contract
- [x] Create `InterchainTokenServiceFactory.sol`
- [x] Support deployment of all chain types
- [x] Add chain type enumeration

### Phase 4: Update Interfaces and Utilities
- [ ] Update `IInterchainTokenService.sol` interface
- [ ] Create chain-specific interfaces
- [ ] Update utility contracts

### Phase 5: Migration and Testing
- [ ] Migrate existing contracts to new structure
- [ ] Update tests for all implementations
- [ ] Ensure backward compatibility

### Phase 6: Documentation and Deployment
- [ ] Update documentation
- [ ] Create deployment scripts
- [ ] Update hardhat configuration

## Contract Structure

### Abstract Base Contract
```solidity
abstract contract AbstractInterchainTokenService {
    // Common ITS functionality
    // Virtual functions for chain-specific operations
}
```

### EVM Implementation
```solidity
contract EVMInterchainTokenService is AbstractInterchainTokenService {
    // Standard ERC20 operations
    // CREATE3 deterministic addresses
    // No additional fees
}
```

### Hedera Implementation
```solidity
contract HederaInterchainTokenService is AbstractInterchainTokenService {
    // HTS precompile operations
    // WHBAR fee integration
    // Non-deterministic addresses
    // Token association handling
}
```

### Hyperliquid Implementation
```solidity
contract HyperliquidInterchainTokenService is EVMInterchainTokenService {
    // EVM base + Hyperliquid-specific features
    // Deployer management
    // Core-EVM linking
}
```

## Benefits of This Approach

### 1. Code Modularity
- Single codebase for all chain types
- Easy to add new chain support
- Clear separation of concerns

### 2. Maintainability
- Common functionality in base contract
- Chain-specific logic isolated
- Easier testing and debugging

### 3. Upgradability
- New features can be added to base contract
- Chain-specific updates don't affect others
- Backward compatibility maintained

### 4. Developer Experience
- Familiar OpenZeppelin pattern
- Clear inheritance hierarchy
- Easy to understand and extend

## Breaking Changes

### Required Changes:
1. **Contract Deployment**: Use factory instead of direct deployment
2. **Interface Updates**: Some functions may have different signatures
3. **Address Resolution**: Chain-specific address lookup methods

### Backward Compatibility:
- Existing deployed contracts remain functional
- Gradual migration path available
- Deprecation warnings for old functions

## Testing Strategy

### Unit Tests
- Test each implementation independently
- Mock chain-specific dependencies
- Verify virtual function overrides

### Integration Tests
- Test factory deployment
- Test cross-chain interactions
- Test chain-specific features

### Migration Tests
- Test migration from old contracts
- Verify data consistency
- Test backward compatibility

## Deployment Strategy

### Phase 1: Deploy Factory
- Deploy `InterchainTokenServiceFactory`
- Deploy all implementation contracts
- Update deployment scripts

### Phase 2: Gradual Migration
- Deploy new implementations alongside existing
- Migrate one chain at a time
- Monitor for issues

### Phase 3: Full Migration
- Deprecate old contracts
- Update all deployments
- Remove old code

## Risk Mitigation

### Technical Risks
- **Complexity**: Modular design increases complexity
- **Gas Costs**: Additional inheritance layers
- **Testing**: More test scenarios required

### Mitigation Strategies
- **Thorough Testing**: Comprehensive test coverage
- **Gradual Rollout**: Phase-by-phase deployment
- **Monitoring**: Close monitoring during migration

## Timeline

### Week 1-2: Development
- Complete abstract base contract
- Implement all chain-specific versions
- Create factory contract

### Week 3: Testing
- Unit tests for all implementations
- Integration tests
- Migration tests

### Week 4: Documentation & Deployment
- Update documentation
- Create deployment scripts
- Deploy to testnet

### Week 5-6: Migration
- Gradual migration to mainnet
- Monitor and fix issues
- Complete migration

## Conclusion

This modularization approach will create a maintainable, extensible ITS that supports multiple chain types while keeping the codebase unified. The OpenZeppelin-inspired pattern ensures familiarity for developers and provides a clear path for future enhancements. 