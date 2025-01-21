---
'@axelar-network/interchain-token-service': minor
---

Remove auto-registration of token metadata in ITS factory registerCustomToken. registerTokenMetadata on ITS should be called instead for every token being linked explicitly.
