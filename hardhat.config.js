require('@nomicfoundation/hardhat-toolbox');
require('solidity-coverage');
require('solidity-docgen');

const fs = require('fs');
const env = process.env.ENV || 'testnet';
const { importNetworks } = require('@axelar-network/axelar-contract-deployments/evm/utils');
const chains = require(`@axelar-network/axelar-contract-deployments/info/${env}.json`);
const keys = fs.existsSync(`${__dirname}/info/keys.json`) ? require(`${__dirname}/info/keys.json`) : undefined; // Load keys if they exist
const { networks, etherscan } = importNetworks(chains, keys);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: '0.8.17',
        settings: {
            evmVersion: process.env.EVM_VERSION || 'london',
            optimizer: {
                enabled: true,
                runs: 99999,
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
            },
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
    },
};
