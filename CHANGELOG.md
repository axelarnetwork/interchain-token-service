# @axelar-network/interchain-token-service

## 2.1.1

### Patch Changes

-   673d4c6: remove automatic migration of tokens since all of them have been manually migrated.

## 2.1.0

### Minor Changes

-   34c1bb4: Add support for linking custom tokens with decimal scaling via `linkToken`.
-   b87baa5: Add support for registering and linking custom tokens to ITS Factory.
-   9ada6d4: Remove callContractWithInterchainToken to reduce bytecode size. Apps should use interchainTransfer instead.
-   8bf4b60: Interchain tokens now get minted/burnt by the token manager to be consistent with custom tokens
-   d61ef1b: Remove auto-registration of token metadata in ITS factory registerCustomToken. registerTokenMetadata on ITS should be called instead for every token being linked explicitly.
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
