# @axelar-network/interchain-token-service

## 2.1.0

### Minor Changes

-   9ada6d4: Remove callContractWithInterchainToken to reduce bytecode size. Apps should use interchainTransfer instead.
-   8bf4b60: Interchain tokens now get minted/burnt by the token manager to be consistent with custom tokens
-   1c09736: Add auto-migration of minter for native interchain tokens
-   869b412: Remove minter arg from deployRemoteInterchainToken. deployRemoteInterchainTokenWithMinter can be used instead.

### Patch Changes

-   1c98f3c: Remove flow limit queries from ITS to reduce bytecode size. They can still be queried from the corresponding token manager.

## 2.0.1

### Patch Changes

-   983a954: remove npm package.json

## 2.0.0

### Major Changes

-   1426b15: Add ITS Hub support to EVM ITS contract

### Minor Changes

-   2da5b3a: ITS deployInterchainToken is restricted from being on ITS on Amplifier chains. The ITS Factory should be used instead
-   38698a2: Remove support for deploying token manager to chains connected via ITS Hub. When deploying ITS to an EVM chain connected via Amplifier / ITS Hub, a trusted address must be set for it's own chain name to the `'hub'` identifier, to prevent deploying the token manager locally. Note that this restriction is temporary. Once the ITS Hub adds support for deploy token manager msg type, the restriction will be removed. Also note that the token manager deployed as part of registering a canonical ITS token from the ITS Factory is not affected by this.
