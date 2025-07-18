require('dotenv').config();
require('@nomicfoundation/hardhat-toolbox');
require('solidity-coverage');
require('solidity-docgen');
require('hardhat-contract-sizer');

const env = process.env.ENV || 'testnet';
const { importNetworks, readJSON } = require('@axelar-network/axelar-chains-config');
const chains = require(`@axelar-network/axelar-chains-config/info/${env}.json`);
const keys = readJSON(`${__dirname}/keys.json`);
const { networks, etherscan } = importNetworks(chains, keys);

const optimizerSettings = {
    enabled: true,
    runs: 1000,
    details: {
        peephole: process.env.COVERAGE === undefined,
        inliner: process.env.COVERAGE === undefined,
        jumpdestRemover: true,
        orderLiterals: true,
        deduplicate: true,
        cse: process.env.COVERAGE === undefined,
        constantOptimizer: true,
        yul: true,
        yulDetails: {
            stackAllocation: true,
        },
    },
};
// For contracts that are fixed to a specific version, we fix the compiler settings as well
const fixedContractCompilerSettings = {
    version: '0.8.21',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        optimizer: {
            ...optimizerSettings,
            runs: 1000,
        },
    },
};
const compilerSettings = {
    version: '0.8.27',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        optimizer: optimizerSettings,
    },
};
const itsCompilerSettings = {
    version: '0.8.27',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        // TODO(hedera) check about using viaIR
        viaIR: true,
        optimizer: {
            ...optimizerSettings,
            runs: 1,
        },
    },
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        compilers: [compilerSettings],
        // Fix the Proxy bytecodes
        overrides: process.env.NO_OVERRIDES
            ? {}
            : {
                  'contracts/proxies/InterchainProxy.sol': fixedContractCompilerSettings,
                  'contracts/proxies/TokenManagerProxy.sol': fixedContractCompilerSettings,
                  'contracts/interchain-token/InterchainToken.sol': fixedContractCompilerSettings,
                  'contracts/test/TestInterchainTokenService.sol': itsCompilerSettings,
                  'contracts/InterchainTokenService.sol': itsCompilerSettings,
              },
    },
    defaultNetwork: 'hedera-local',
    networks: {
        ...networks,
        'hedera-local': {
            url: process.env.HEDERA_LOCAL_RPC_URL ?? 'http://localhost:7546',
            consensusUrl: process.env.HEDERA_LOCAL_CONSENSUS_URL ?? 'http://localhost:50211',
            nodeId: process.env.HEDERA_LOCAL_NODE_ID ?? '0.0.3',
            operatorKey: process.env.HEDERA_PK ?? '0x105d050185ccb907fba04dd92d8de9e32c18305e097ab41dadda21489a211524',
            operatorId: process.env.HEDERA_ACCOUNT_ID ?? '0.0.1012',
            name: 'Hedera Local',
            accounts: [
                '0x105d050185ccb907fba04dd92d8de9e32c18305e097ab41dadda21489a211524',
                '0x2e1d968b041d84dd120a5860cee60cd83f9374ef527ca86996317ada3d0d03e7',
                '0x45a5a7108a18dd5013cf2d5857a28144beadc9c70b3bdbd914e38df4e804b8d8',
            ],
            chainId: 298,
        },
    },
    etherscan,
    mocha: {
        timeout: 1000000,
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        excludeContracts: ['contracts/test'],
    },
    contractSizer: {
        runOnCompile: process.env.CHECK_CONTRACT_SIZE,
        strict: process.env.CHECK_CONTRACT_SIZE,
        except: ['contracts/test'],
    },
    docgen: {
        path: 'docs',
        clear: true,
        pages: 'files',
    },
};
