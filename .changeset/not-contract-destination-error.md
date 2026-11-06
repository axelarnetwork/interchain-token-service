---
'@axelar-network/interchain-token-service': patch
---

use a `NotContract` error when an interchain transfer with data targets a destination without code, instead of reverting with empty revert data
