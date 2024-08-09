# Interchain Token Service

## Introduction

This repo provides an implementation for an Interchain Token Service and an Interchain Token using it. The interchain token service is meant to allow users/developers to easily create their own token bridge. All the underlying interchain communication is done by the service, and the deployer can either use an `InterchainToken` that the service provides, or their own implementations. There are quite a few different possible configurations for bridges, and any user of any deployed bridge needs to trust the deployer of said bridge, much like any user of a token needs to trust the operator of said token. We plan to eventually remove upgradability from the service to make this protocol more trustworthy. Please reference the [design description](./DESIGN.md) for more details on the design. Please look at the [docs](./docs/index.md) for more details on the contracts.

## Build

To build and run tests, do the following

```bash
npm ci

npm run build
```

## Test

```bash
npm run test
```

### Gas Report

Generate gas report

```bash
REPORT_GAS=true npm run test
```

### Coverage

Generate test coverage report

```bash
npm run coverage
```

Test coverage reports of the `main` branch can also be found on [Codecov](https://app.codecov.io/gh/axelarnetwork/interchain-token-service).

## Deployment Guide

To learn more about the deployment process, please refer to [this repo](https://github.com/axelarnetwork/axelar-contract-deployments).
