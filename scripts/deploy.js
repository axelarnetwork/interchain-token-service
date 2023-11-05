const { ethers } = require('hardhat');
const { Contract } = ethers;
const InterchainTokenServiceProxy = require('../artifacts/contracts/proxies/InterchainTokenServiceProxy.sol/InterchainTokenServiceProxy.json');
const InterchainTokenFactoryProxy = require('../artifacts/contracts/proxies/InterchainTokenFactoryProxy.sol/InterchainTokenFactoryProxy.json');
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');
const { create3DeployContract, getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');

async function deployContract(wallet, contractName, args = []) {
    const factory = await ethers.getContractFactory(contractName, wallet);
    const contract = await factory.deploy(...args).then((d) => d.deployed());

    return contract;
}

async function deployAddressTracker(wallet, chainName, interchainTokenServiceAddress = '', evmChains = []) {
    const addressTracker = deployContract(wallet, 'AddressTracker', [
        wallet.address,
        chainName,
        evmChains,
        evmChains.map(() => interchainTokenServiceAddress),
    ]);
    return addressTracker;
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
    remoteAddressValidatorAddress,
    interchainTokenFactoryAddress,
    tokenManagerImplementations,
    deploymentKey,
    operatorAddress = wallet.address,
) {
    const implementation = await deployContract(wallet, 'InterchainTokenService', [
        tokenManagerDeployerAddress,
        interchainTokenDeployerAddress,
        gatewayAddress,
        gasServiceAddress,
        remoteAddressValidatorAddress,
        interchainTokenFactoryAddress,
        tokenManagerImplementations,
    ]);
    const proxy = await create3DeployContract(create3DeployerAddress, wallet, InterchainTokenServiceProxy, deploymentKey, [
        implementation.address,
        wallet.address,
        operatorAddress,
    ]);
    const service = new Contract(proxy.address, implementation.interface, wallet);
    return service;
}

async function deployInterchainTokenFactory(
    wallet,
    create3DeployerAddress,
    interchainTokenServiceAddress,
    deploymentKey,
) {
    const implementation = await deployContract(wallet, 'InterchainTokenFactory', [
        interchainTokenServiceAddress
    ]);
    const proxy = await create3DeployContract(create3DeployerAddress, wallet, InterchainTokenFactoryProxy, deploymentKey, [
        implementation.address,
        wallet.address,
    ]);
    const factory = new Contract(proxy.address, implementation.interface, wallet);
    return factory;
}

async function deployTokenManagerImplementations(wallet, interchainTokenServiceAddress) {
    const implementations = [];

    for (const type of ['MintBurn', 'MintBurnFrom', 'LockUnlock', 'LockUnlockFee']) {
        const impl = await deployContract(wallet, `TokenManager${type}`, [interchainTokenServiceAddress]);
        implementations.push(impl);
    }

    return implementations;
}

async function deployAll(wallet, chainName, evmChains = [], deploymentKey = 'interchainTokenService', factoryDeploymentKey = deploymentKey + 'Factory') {
    const create3Deployer = await new ethers.ContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet)
        .deploy()
        .then((d) => d.deployed());
    const gateway = await deployMockGateway(wallet);
    const gasService = await deployGasService(wallet);
    const tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
    const interchainToken = await deployContract(wallet, 'InterchainToken');
    const interchainTokenDeployer = await deployContract(wallet, 'InterchainTokenDeployer', [interchainToken.address]);
    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const interchainAddressTracker = await deployAddressTracker(wallet, chainName, interchainTokenServiceAddress, evmChains);
    const tokenManagerImplementations = await deployTokenManagerImplementations(wallet, interchainTokenServiceAddress);

    const interchainTokenFactoryAddress = await getCreate3Address(create3Deployer.address, wallet, factoryDeploymentKey);

    const service = await deployInterchainTokenService(
        wallet,
        create3Deployer.address,
        tokenManagerDeployer.address,
        interchainTokenDeployer.address,
        gateway.address,
        gasService.address,
        interchainAddressTracker.address,
        interchainTokenFactoryAddress,
        tokenManagerImplementations.map((impl) => impl.address),
        deploymentKey,
    );

    const factory = await deployInterchainTokenFactory(wallet, create3Deployer.address, interchainTokenServiceAddress, factoryDeploymentKey);
    return [service, gateway, gasService, factory];
}

module.exports = {
    deployContract,
    deployRemoteAddressValidator: deployAddressTracker,
    deployMockGateway,
    deployTokenManagerImplementations,
    deployGasService,
    deployInterchainTokenService,
    deployAll,
};
