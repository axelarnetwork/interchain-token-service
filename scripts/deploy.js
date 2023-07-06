const { ethers } = require('hardhat');
const { Contract } = ethers;
const { defaultAbiCoder } = ethers.utils;
const InterchainTokenServiceProxy = require('../artifacts/contracts/proxies/InterchainTokenServiceProxy.sol/InterchainTokenServiceProxy.json');
const { deployCreate3Contract, getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');

async function deployContract(wallet, contractName, args = []) {
    const factory = await ethers.getContractFactory(contractName, wallet);
    const contract = await factory.deploy(...args);

    return contract;
}

async function deployRemoteAddressValidator(wallet, interchainTokenServiceAddress) {
    const remoteAddressValidatorImpl = await deployContract(wallet, 'RemoteAddressValidator', [interchainTokenServiceAddress]);
    const params = defaultAbiCoder.encode(['string[]', 'string[]'], [[], []]);

    const remoteAddressValidatorProxy = await deployContract(wallet, 'RemoteAddressValidatorProxy', [remoteAddressValidatorImpl.address, wallet.address, params]);
    const remoteAddressValidator = new Contract(remoteAddressValidatorProxy.address, remoteAddressValidatorImpl.interface, wallet);
    return remoteAddressValidator;
}

async function deployMockGateway(wallet) {
    const gateway = await deployContract(wallet, 'MockAxelarGateway');
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
    standardizedTokenDeployerAddress,
    gatewayAddress,
    gasServiceAddress,
    remoteAddressValidatorAddress,
    tokenManagerImplementations,
    chainName,
    deploymentKey,
    operatorAddress = wallet.address,
) {
    const implementation = await deployContract(wallet, 'InterchainTokenService', [
        tokenManagerDeployerAddress,
        standardizedTokenDeployerAddress,
        gatewayAddress,
        gasServiceAddress,
        remoteAddressValidatorAddress,
        tokenManagerImplementations,
        chainName,
    ]);
    const proxy = await deployCreate3Contract(create3DeployerAddress, wallet, InterchainTokenServiceProxy, deploymentKey, [
        implementation.address,
        wallet.address,
        operatorAddress,
    ]);
    const service = new Contract(proxy.address, implementation.interface, wallet);
    return service;
}

async function deployTokenManagerImplementations(wallet, interchainTokenServiceAddress) {
    const implementations = [];

    for (const type of ['LockUnlock', 'MintBurn', 'LiquidityPool']) {
        const impl = await deployContract(wallet, `TokenManager${type}`, [interchainTokenServiceAddress]);
        implementations.push(impl);
    }

    return implementations;
}

async function deployAll(wallet, chainName, deploymentKey = 'interchainTokenService') {
    const create3Deployer = await deployContract(wallet, 'Create3Deployer');
    const gateway = await deployMockGateway(wallet);
    const gasService = await deployGasService(wallet);
    const tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', [create3Deployer.address]);
    const standardizedTokenLockUnlock = await deployContract(wallet, 'StandardizedTokenLockUnlock');
    const standardizedTokenMintBurn = await deployContract(wallet, 'StandardizedTokenMintBurn');
    const standardizedTokenDeployer = await deployContract(wallet, 'StandardizedTokenDeployer', [
        create3Deployer.address,
        standardizedTokenLockUnlock.address,
        standardizedTokenMintBurn.address,
    ]);
    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const remoteAddressValidator = await deployRemoteAddressValidator(wallet, interchainTokenServiceAddress);
    const tokenManagerImplementations = await deployTokenManagerImplementations(wallet, interchainTokenServiceAddress);

    const service = await deployInterchainTokenService(
        wallet,
        create3Deployer.address,
        tokenManagerDeployer.address,
        standardizedTokenDeployer.address,
        gateway.address,
        gasService.address,
        remoteAddressValidator.address,
        tokenManagerImplementations.map((impl) => impl.address),
        chainName,
        deploymentKey,
    );
    return [service, gateway, gasService];
}

module.exports = {
    deployContract,
    deployRemoteAddressValidator,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployAll,
};
