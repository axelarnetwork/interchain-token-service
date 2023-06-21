const { ethers } = require('hardhat');
const { Contract } = ethers;
const InterchainTokenServiceProxy = require('../artifacts/contracts/proxies/InterchainTokenServiceProxy.sol/InterchainTokenServiceProxy.json');
const { deployCreate3Contract, getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');

async function deployContract(wallet, contractName, args = []) {
    const factory = await ethers.getContractFactory(contractName, wallet);
    const contract = await factory.deploy(...args);

    return contract;
}

async function deployLinkerRouter(wallet, interchainTokenServiceAddress) {
    const linkerRouterImpl = await deployContract(wallet, 'LinkerRouter', [interchainTokenServiceAddress, [], []]);

    const linkerRouterProxy = await deployContract(wallet, 'LinkerRouterProxy', [linkerRouterImpl.address, wallet.address]);
    const linkerRouter = new Contract(linkerRouterProxy.address, linkerRouterImpl.interface, wallet);
    return linkerRouter;
}

async function deployMockGateway(wallet) {
    const tokenDeployer = await deployContract(wallet, 'TokenDeployer', []);
    const gateway = await deployContract(wallet, 'MockAxelarGateway', [tokenDeployer.address]);
    return gateway;
}

async function deployGasService(wallet) {
    const gasService = await deployContract(wallet, 'AxelarGasService', []);
    return gasService;
}

async function deployInterchainTokenService(
    wallet,
    create3DeployerAddress,
    tokenManagerDeployerAddress,
    standardizedTokenDeployerAddress,
    gatewayAddress,
    gasServiceAddress,
    linkerRouterAddress,
    tokenManagerImplementations,
    chainName,
    deploymentKey,
) {
    const implementation = await deployContract(wallet, 'InterchainTokenService', [
        tokenManagerDeployerAddress,
        standardizedTokenDeployerAddress,
        gatewayAddress,
        gasServiceAddress,
        linkerRouterAddress,
        tokenManagerImplementations,
        chainName,
    ]);
    const proxy = await deployCreate3Contract(create3DeployerAddress, wallet, InterchainTokenServiceProxy, deploymentKey, [
        implementation.address,
        wallet.address,
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
    const standardizedToken = await deployContract(wallet, 'StandardizedToken');
    const standardizedTokenDeployer = await deployContract(wallet, 'StandardizedTokenDeployer', [
        create3Deployer.address,
        standardizedToken.address,
    ]);
    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const linkerRouter = await deployLinkerRouter(wallet, interchainTokenServiceAddress);
    const tokenManagerImplementations = await deployTokenManagerImplementations(wallet, interchainTokenServiceAddress);

    const service = await deployInterchainTokenService(
        wallet,
        create3Deployer.address,
        tokenManagerDeployer.address,
        standardizedTokenDeployer.address,
        gateway.address,
        gasService.address,
        linkerRouter.address,
        tokenManagerImplementations.map((impl) => impl.address),
        chainName,
        deploymentKey,
    );
    return [service, gateway, gasService];
}

module.exports = {
    deployContract,
    deployLinkerRouter,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployAll,
};
