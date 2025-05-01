'use strict';

const fs = require('fs');
const path = require('path');
const { ethers, network, config } = require('hardhat');
const { expect } = require('chai');
const { defaultAbiCoder, keccak256 } = ethers.utils;
const {
    MESSAGE_TYPE_INTERCHAIN_TRANSFER,
    MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN,
    MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER,
    MESSAGE_TYPE_LINK_TOKEN,
    MESSAGE_TYPE_REGISTER_TOKEN_METADATA,
    INVALID_MESSAGE_TYPE,
} = require('./constants');

function getRandomBytes32() {
    return keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

const getSaltFromKey = (key) => {
    return keccak256(defaultAbiCoder.encode(['string'], [key.toString()]));
};

const getRandomInt = (max) => {
    return Math.floor(Math.random() * max);
};

const isHardhat = network.name === 'hardhat';

const getGasOptions = () => {
    return network.config.blockGasLimit ? { gasLimit: network.config.blockGasLimit.toString() } : { gasLimit: 5e6 }; // defaults to 5M gas for revert tests to work correctly
};

const expectRevert = async (txFunc, contract, error, args) => {
    if (network.config.skipRevertTests || contract === undefined) {
        await expect(txFunc(getGasOptions())).to.be.reverted;
    } else {
        if (args) {
            await expect(txFunc(null))
                .to.be.revertedWithCustomError(contract, error)
                .withArgs(...args);
        } else {
            await expect(txFunc(null)).to.be.revertedWithCustomError(contract, error);
        }
    }
};

const getChainId = () => {
    return network.config.chainId;
};

const getPayloadAndProposalHash = async (commandID, target, nativeValue, calldata, timeDelay) => {
    let eta;

    if (timeDelay) {
        const block = await ethers.provider.getBlock('latest');
        eta = block.timestamp + timeDelay - 12; // 12 second buffer for live network tests
    } else {
        eta = 0;
    }

    const proposalHash = keccak256(defaultAbiCoder.encode(['address', 'bytes', 'uint256'], [target, calldata, nativeValue]));

    const payload = defaultAbiCoder.encode(
        ['uint256', 'address', 'bytes', 'uint256', 'uint256'],
        [commandID, target, calldata, nativeValue, eta],
    );

    return [payload, proposalHash, eta];
};

const waitFor = async (timeDelay) => {
    if (isHardhat) {
        await network.provider.send('evm_increaseTime', [timeDelay]);
        await network.provider.send('evm_mine');
    } else {
        await new Promise((resolve) => setTimeout(resolve, timeDelay * 1000));
    }
};

const gasReports = {};
let gasReportScheduled = false;

const writeGasReport = () => {
    const report = Object.entries(gasReports)
        .flatMap(([contract, report]) => [
            `## ${contract} gas report:`,
            ...Object.entries(report).map(([key, value]) => `  |> ${key}\n  ==${value.toLocaleString().padStart(10)} gas`),
        ])
        .join('\n\n');

    fs.writeFileSync('gas.report.log', report);
};

const gasReporter = (contact) => (tx, message) => {
    if (process.env.REPORT_GAS === undefined) return tx;

    if (message) {
        tx.then((tx) =>
            tx.wait().then((receipt) => {
                if (!gasReports[contact]) gasReports[contact] = {};
                gasReports[contact][message] = receipt.gasUsed.toNumber();
            }),
        );
    }

    if (!gasReportScheduled) {
        gasReportScheduled = true;
        process.on('exit', writeGasReport);
    }

    return tx;
};

const getEVMVersion = () => {
    return config.solidity.compilers[0].settings.evmVersion;
};

function findProjectRoot(startDir) {
    let currentDir = startDir;

    while (currentDir !== path.parse(currentDir).root) {
        const potentialPackageJson = path.join(currentDir, 'package.json');

        if (fs.existsSync(potentialPackageJson)) {
            return currentDir;
        }

        currentDir = path.resolve(currentDir, '..');
    }

    throw new Error('Unable to find project root');
}

function findContractPath(dir, contractName) {
    const files = fs.readdirSync(dir);

    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat && stat.isDirectory()) {
            const recursivePath = findContractPath(filePath, contractName);

            if (recursivePath) {
                return recursivePath;
            }
        } else if (file === `${contractName}.json`) {
            return filePath;
        }
    }
}

function getContractPath(contractName, projectRoot = '') {
    if (projectRoot === '') {
        projectRoot = findProjectRoot(__dirname);
    }

    projectRoot = path.resolve(projectRoot);

    const searchDirs = [
        path.join(projectRoot, 'artifacts', 'contracts'),
        path.join(projectRoot, 'node_modules', '@axelar-network', 'axelar-gmp-sdk-solidity', 'artifacts', 'contracts'),
        path.join(projectRoot, 'node_modules', '@axelar-network', 'axelar-cgp-solidity', 'artifacts', 'contracts'),
    ];

    for (const dir of searchDirs) {
        if (fs.existsSync(dir)) {
            const contractPath = findContractPath(dir, contractName);

            if (contractPath) {
                return contractPath;
            }
        }
    }

    throw new Error(`Contract path for ${contractName} must be entered manually.`);
}

function getContractJSON(contractName, artifactPath) {
    let contractPath;

    if (artifactPath) {
        contractPath = artifactPath.endsWith('.json') ? artifactPath : artifactPath + contractName + '.sol/' + contractName + '.json';
    } else {
        contractPath = getContractPath(contractName);
    }

    try {
        const contractJson = require(contractPath);
        return contractJson;
    } catch (err) {
        throw new Error(`Failed to load contract JSON for ${contractName} at path ${contractPath} with error: ${err}`);
    }
}

function resolveITSMessageType(messageType, values) {
    switch (messageType) {
        case MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN:
            if (values.length === 7) {
                return ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'];
            }

            return ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'];

        case MESSAGE_TYPE_LINK_TOKEN:
            return ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'];

        case MESSAGE_TYPE_INTERCHAIN_TRANSFER:
            return ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'];

        case MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER:
            return ['uint256', 'bytes32', 'bytes', 'uint256'];

        case MESSAGE_TYPE_REGISTER_TOKEN_METADATA:
            return ['uint256', 'bytes', 'uint8'];

        case INVALID_MESSAGE_TYPE:
            return ['uint256', 'bytes32', 'bytes', 'uint256'];

        default:
            throw new Error(`Unknown ITS message type: ${messageType}`);
    }
}

function wrapPayload(wrapperType, chain, innerPayload) {
    const wrappedPayload = defaultAbiCoder.encode(['uint256', 'string', 'bytes'], [wrapperType, chain, innerPayload]);
    return {
        payload: wrappedPayload,
        payloadHash: keccak256(wrappedPayload),
    };
}

/**
 * Encodes an Interchain Token Service (ITS) message with wrapping.
 * Supports single chain (returns object) or array of chains (returns array of objects).
 *
 * @param {number} wrapperType - Wrapper message type (e.g. RECEIVE_FROM_HUB, SEND_TO_HUB)
 * @param {string|string[]} chain - Single chain name or array of chains
 * @param {Array<any>} values - Values for the ITS payload (first item must be messageType)
 * @returns {{ payload: string, hash: string } | { payload: string, hash: string }[]} - Wrapped payload(s) and hash(es)
 */
function encodeITSPayload(wrapperType, chain, values) {
    const messageType = resolveITSMessageType(values[0], values);
    const payload = defaultAbiCoder.encode(messageType, values);

    if (Array.isArray(chain)) {
        return chain.map((chain) => wrapPayload(wrapperType, chain, payload));
    }

    return wrapPayload(wrapperType, chain, payload);
}

module.exports = {
    getRandomBytes32,
    getSaltFromKey,
    getRandomInt,
    isHardhat,
    getChainId,
    getGasOptions,
    expectRevert,
    getPayloadAndProposalHash,
    waitFor,
    gasReporter,
    getEVMVersion,
    getContractJSON,
    encodeITSPayload,
};
