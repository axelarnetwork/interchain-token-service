---
'@axelar-network/interchain-token-service': patch
---

Remove flow limit queries from ITS to reduce bytecode size. They can still be queried from the corresponding token manager.
