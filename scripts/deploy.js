const { ethers } = require('hardhat');
const {
    Contract,
    utils: { defaultAbiCoder },
} = ethers;
const Proxy = require('../artifacts/contracts/proxies/InterchainProxy.sol/InterchainProxy.json');
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');
const { create3DeployContract, getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { ITS_HUB_ADDRESS } = require('../test/constants');
const { deployHTS } = require('./deploy-hts');

const HTS_LIBRARY_NAME = 'contracts/hedera/HTS.sol:HTS';

// List of contracts that depend on HTS library
const HTS_DEPENDENT_CONTRACTS = [
    'InterchainTokenService',
    'InterchainTokenDeployer',
    'TokenManager',
    // Test
    'TestInterchainTokenService',
    'TestInterchainTokenDeployer',
    'TestTokenManager',
];

// Context object to hold deployment state
const deploymentContext = {
    htsAddress: null,
};

function getCurrentHTSAddress() {
    return deploymentContext.htsAddress;
}

async function deployContract(wallet, contractName, args = [], additionalLibraries = {}, htsAddress = null) {
    const libraries = { ...additionalLibraries };

    // Automatically add HTS library for dependent contracts
    if (HTS_DEPENDENT_CONTRACTS.includes(contractName)) {
        let currentHtsAddress = htsAddress || deploymentContext.htsAddress;

        if (!currentHtsAddress) {
            console.log('Deploying HTS library for', contractName);
            currentHtsAddress = await deployHTS(wallet);
            console.log('HTS library deployed at:', currentHtsAddress);
            deploymentContext.htsAddress = currentHtsAddress;
        }

        libraries[HTS_LIBRARY_NAME] = currentHtsAddress;
    }

    const factory = await ethers.getContractFactory(contractName, {
        signer: wallet,
        libraries,
    });
    const contract = await factory.deploy(...args).then((d) => d.deployed());

    console.log(`Deployed ${contractName} to ${contract.address}`);

    return contract;
}

async function deployMockGateway(wallet) {
    const gateway = await deployContract(wallet, 'MockGateway');
    return gateway;
}

async function deployGasService(wallet) {
    const gasService = await deployContract(wallet, 'AxelarGasService', [wallet.address]);
    return gasService;
}

async function deployInterchainTokenService(
    wallet,
    create3DeployerAddress,
    tokenManagerDeployerAddress,
    interchainTokenDeployerAddress,
    gatewayAddress,
    gasServiceAddress,
    interchainTokenFactoryAddress,
    tokenManagerAddress,
    tokenHandlerAddress,
    chainName,
    itsHubAddress,
    evmChains = [],
    deploymentKey,
    ownerAddress = wallet.address,
    operatorAddress = wallet.address,
) {
    const implementation = await deployContract(wallet, 'InterchainTokenService', [
        tokenManagerDeployerAddress,
        interchainTokenDeployerAddress,
        gatewayAddress,
        gasServiceAddress,
        interchainTokenFactoryAddress,
        chainName,
        itsHubAddress,
        tokenManagerAddress,
        tokenHandlerAddress,
    ]);
    const proxy = await create3DeployContract(create3DeployerAddress, wallet, Proxy, deploymentKey, [
        implementation.address,
        ownerAddress,
        defaultAbiCoder.encode(['address', 'string', 'string[]'], [operatorAddress, chainName, evmChains]),
    ]);
    const service = new Contract(proxy.address, implementation.interface, wallet);
    return service;
}

async function deployInterchainTokenFactory(wallet, create3DeployerAddress, interchainTokenServiceAddress, deploymentKey) {
    const implementation = await deployContract(wallet, 'InterchainTokenFactory', [interchainTokenServiceAddress]);
    const proxy = await create3DeployContract(create3DeployerAddress, wallet, Proxy, deploymentKey, [
        implementation.address,
        wallet.address,
        '0x',
    ]);
    const factory = new Contract(proxy.address, implementation.interface, wallet);
    return factory;
}

async function deployAll(
    wallet,
    chainName,
    itsHubAddress = ITS_HUB_ADDRESS,
    evmChains = [],
    deploymentKey = 'InterchainTokenService',
    factoryDeploymentKey = deploymentKey + 'Factory',
    htsAddress = null,
) {
    // Reset deployment context
    deploymentContext.htsAddress = htsAddress;

    const create3Deployer = await new ethers.ContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet)
        .deploy()
        .then((d) => d.deployed());
    const gateway = await deployMockGateway(wallet);
    const gasService = await deployGasService(wallet);

    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
    const interchainToken = await deployContract(wallet, 'InterchainToken', [interchainTokenServiceAddress]);
    const interchainTokenDeployer = await deployContract(wallet, 'InterchainTokenDeployer');
    const tokenManager = await deployContract(wallet, 'TokenManager', [interchainTokenServiceAddress]);
    const tokenHandler = await deployContract(wallet, 'TokenHandler', []);

    const interchainTokenFactoryAddress = await getCreate3Address(create3Deployer.address, wallet, factoryDeploymentKey);

    const service = await deployInterchainTokenService(
        wallet,
        create3Deployer.address,
        tokenManagerDeployer.address,
        interchainTokenDeployer.address,
        gateway.address,
        gasService.address,
        interchainTokenFactoryAddress,
        tokenManager.address,
        tokenHandler.address,
        chainName,
        itsHubAddress,
        evmChains,
        deploymentKey,
    );

    const tokenFactory = await deployInterchainTokenFactory(
        wallet,
        create3Deployer.address,
        interchainTokenServiceAddress,
        factoryDeploymentKey,
    );

    return {
        service,
        gateway,
        gasService,
        tokenFactory,
        create3Deployer,
        tokenManagerDeployer,
        interchainToken,
        interchainTokenDeployer,
        tokenManager,
        tokenHandler,
        htsAddress: deploymentContext.htsAddress,
    };
}

module.exports = {
    deployContract,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployInterchainTokenFactory,
    deployAll,
    getCurrentHTSAddress,
};
