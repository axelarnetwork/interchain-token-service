---
'@axelar-network/interchain-token-service': patch
---

Prevent the deployment of the token manager on its hub. Now, require registering the trusted address for the self chain if it is connected to the ITS hub, to ensure this check is applied correctly. Note: This deploy token manager restriction is temporary for chains connected via the Hub. Once the ITS hub adds support for it, the restriction will be removed.
