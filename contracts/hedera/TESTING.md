# Local Hedera devnet for testing

Follow [instructions for setting up a local Hedera devnet](https://github.com/hiero-ledger/hiero-local-node). It is recommended to install the cli tool and run `hedera start --dev --verbose=trace`.

If starting the local node on a server, you can use the `--host` option to specify the host address. For example, `hedera start --dev --verbose=trace --host=<host>`. Before that, make the following env var available: `export DOCKER_LOCAL_MIRROR_NODE_URL="http://<host>:5551"` to be able to inspect the local node in the Hedera explorer, available at `http://<host>:8090`.

## Test Configuration

Create a `.env` file in the root directory with the following content:

```sh
HEDERA_PK=0x105d050185ccb907fba04dd92d8de9e32c18305e097ab41dadda21489a211524
HEDERA_ACCOUNT_ID=0.0.1012
HEDERA_NODE_ID=0.0.3
HEDERA_LOCAL_RPC_URL=http://<host>:7546
HEDERA_LOCAL_CONSENSUS_URL=http://<host>:50211
```

These are the default values for the local Hedera devnet. Make sure to replace `<host>` with the actual host address (`localhost` or the server's host).
