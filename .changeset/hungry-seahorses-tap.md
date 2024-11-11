---
'@axelar-network/interchain-token-service': patch
---

Remove support for deploying token manager to chains connected via ITS Hub. When deploying ITS to an EVM chain connected via Amplifier / ITS Hub, a trusted address must be set for it's own chain name to the `'hub'` identifier, to prevent deploying the token manager locally. Note that this restriction is temporary. Once the ITS Hub adds support for deploy token manager msg type, the restriction will be removed. Also note that the token manager deployed as part of registering a canonical ITS token from the ITS Factory is not affected by this.
