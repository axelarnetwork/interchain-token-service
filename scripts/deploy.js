const { ethers } = require('hardhat');
const {
    Contract,
    utils: { defaultAbiCoder },
} = ethers;
const Proxy = require('../artifacts/contracts/proxies/InterchainProxy.sol/InterchainProxy.json');
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');
const { create3DeployContract, getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');

async function deployContract(wallet, contractName, args = []) {
    const factory = await ethers.getContractFactory(contractName, wallet);
    const contract = await factory.deploy(...args).then((d) => d.deployed());

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
    gatewayCaller,
    chainName,
    evmChains = [],
    deploymentKey,
    ownerAddress = wallet.address,
    operatorAddress = wallet.address,
) {
    const interchainTokenServiceAddress = await getCreate3Address(create3DeployerAddress, wallet, deploymentKey);

    const implementation = await deployContract(wallet, 'InterchainTokenService', [
        tokenManagerDeployerAddress,
        interchainTokenDeployerAddress,
        gatewayAddress,
        gasServiceAddress,
        interchainTokenFactoryAddress,
        chainName,
        tokenManagerAddress,
        tokenHandlerAddress,
        gatewayCaller,
    ]);
    const proxy = await create3DeployContract(create3DeployerAddress, wallet, Proxy, deploymentKey, [
        implementation.address,
        ownerAddress,
        defaultAbiCoder.encode(
            ['address', 'string', 'string[]', 'string[]'],
            [operatorAddress, chainName, evmChains, evmChains.map(() => interchainTokenServiceAddress)],
        ),
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
    evmChains = [],
    deploymentKey = 'InterchainTokenService',
    factoryDeploymentKey = deploymentKey + 'Factory',
) {
    const create3Deployer = await new ethers.ContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet)
        .deploy()
        .then((d) => d.deployed());
    const gateway = await deployMockGateway(wallet);
    const gasService = await deployGasService(wallet);

    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
    const interchainToken = await deployContract(wallet, 'InterchainToken', [interchainTokenServiceAddress]);
    const interchainTokenDeployer = await deployContract(wallet, 'InterchainTokenDeployer', [interchainToken.address]);
    const tokenManager = await deployContract(wallet, 'TokenManager', [interchainTokenServiceAddress]);
    const tokenHandler = await deployContract(wallet, 'TokenHandler', [gateway.address]);
    const gatewayCaller = await deployContract(wallet, 'GatewayCaller', [gateway.address, gasService.address]);

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
        gatewayCaller.address,
        chainName,
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
        gatewayCaller,
    };
}

async function deployWithTestGatewayCaller(
    wallet,
    chainName,
    evmChains = [],
    gateway,
    gasService,
    tokenManagerDeployer,
    interchainTokenDeployer,
    tokenHandler,
    deploymentKey = 'InterchainTokenService',
    factoryDeploymentKey = deploymentKey + 'Factory',
) {
    const create3Deployer = await new ethers.ContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet)
        .deploy()
        .then((d) => d.deployed());

    const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
    const tokenManager = await deployContract(wallet, 'TokenManager', [interchainTokenServiceAddress]);
    const gatewayCaller = await deployContract(wallet, 'TestGatewayCaller');
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
        gatewayCaller.address,
        chainName,
        evmChains,
        deploymentKey,
    );

    return service;
}

module.exports = {
    deployContract,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployAll,
    deployWithTestGatewayCaller,
};
