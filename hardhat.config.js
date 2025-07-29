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
        optimizer: {
            ...optimizerSettings,
            runs: 100,
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
                  // Fix the proxy bytecodes
                  'contracts/proxies/InterchainProxy.sol': fixedContractCompilerSettings,
                  'contracts/proxies/TokenManagerProxy.sol': fixedContractCompilerSettings,

                  // Fix the InterchainToken bytecode to avoid having multiple token versions in the wild
                  'contracts/interchain-token/InterchainToken.sol': fixedContractCompilerSettings,
                  'contracts/hyperliquid/HyperliquidInterchainToken.sol': fixedContractCompilerSettings,

                  // Reduce bytecode size for ITS contracts to stay under the limit
                  'contracts/test/TestInterchainTokenService.sol': itsCompilerSettings,
                  'contracts/InterchainTokenService.sol': itsCompilerSettings,
                  'contracts/hyperliquid/HyperliquidInterchainTokenService.sol': itsCompilerSettings,
              },
    },
    defaultNetwork: 'hardhat',
    networks,
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
