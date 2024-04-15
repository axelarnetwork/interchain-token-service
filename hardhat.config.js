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
const compilerSettings = {
    version: '0.8.21',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        optimizer: optimizerSettings,
    },
};
const itsCompilerSettings = {
    version: '0.8.21',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        optimizer: {
            ...optimizerSettings,
            runs: 800, // Reduce runs to keep bytecode size under limit
        },
    },
};
const itsTestCompilerSettings = {
    version: '0.8.21',
    settings: {
        evmVersion: process.env.EVM_VERSION || 'london',
        optimizer: {
            ...optimizerSettings,
            runs: 200, // Reduce runs to keep bytecode size under limit
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
                  'contracts/proxies/Proxy.sol': compilerSettings,
                  'contracts/proxies/TokenManagerProxy.sol': compilerSettings,
                  'contracts/InterchainTokenService.sol': itsCompilerSettings,
                  'contracts/test/TestInterchainTokenService.sol': itsTestCompilerSettings,
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
};
