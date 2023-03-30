'use strict';

require('dotenv').config();

const TokenDeployer = require('../artifacts/contracts/utils/TokenDeployer.sol/TokenDeployer.json');
const LinkerRouter = require('../artifacts/contracts/linkerRouter/LinkerRouter.sol/LinkerRouter.json');
const LinkerRouterProxy = require('../artifacts/contracts/proxies/LinkerRouterProxy.sol/LinkerRouterProxy.json');

const TokenService = require('../artifacts/contracts/interchainTokenService/InterchainTokenService.sol/InterchainTokenService.json');
const TokenServiceProxy = require('../artifacts/contracts/proxies/InterchainTokenServiceProxy.sol/InterchainTokenServiceProxy.json');

const BytecodeServer = require('../artifacts/contracts/utils/BytecodeServer.sol/BytecodeServer.json');
const Token = require('../artifacts/contracts/utils/ERC20BurnableMintable.sol/ERC20BurnableMintable.json');
const TokenProxy = require('../artifacts/contracts/proxies/TokenProxy.sol/TokenProxy.json');
const { deployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/utils');
const { setJSON } = require('@axelar-network/axelar-local-dev');
const { deployCreate3Upgradable } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { Contract } = require('ethers');
const chains = require(`../info/${process.env.ENV}.json`);

const interchainTokenServiceKey = 'interchainTokenServiceKey';

async function deployTokenDeployer(chain, wallet) {
    if (chain.tokenDeployer) return new Contract(chain.tokenDeployer, TokenDeployer.abi, wallet);

    console.log(`Deploying ERC20BurnableMintable.`);
    const token = await deployContract(wallet, Token, []);
    chain.tokenImplementation = token.address;
    console.log(`Deployed at: ${token.address}`);

    console.log(`Deploying Bytecode Server.`);
    const bytecodeServer = await deployContract(wallet, BytecodeServer, [TokenProxy.bytecode]);
    chain.bytecodeServer = bytecodeServer.address;
    console.log(`Deployed at: ${bytecodeServer.address}`);

    console.log(`Deploying Token Deployer.`);
    const tokenDeployer = await deployContract(wallet, TokenDeployer, [chain.create3Deployer, bytecodeServer.address, token.address]);
    chain.tokenDeployer = tokenDeployer.address;
    console.log(`Deployed at: ${tokenDeployer.address}`);

    setJSON(chains, `./info/${process.env.ENV}.json`);
    return tokenDeployer;
}

async function deployLinkerRouter(chain, wallet) {
    if (chain.linkerRouter) return new Contract(chain.linkerRouter, LinkerRouter.abi, wallet);

    console.log(`Deploying Linker Router.`);
    const interchainTokenServiceAddress = getCreate3Address(chain.create3Deployer, wallet, interchainTokenServiceKey);
    const linkerRouter = await deployContract(wallet, LinkerRouter, [interchainTokenServiceAddress, [], []]);
    console.log(`Deployed at: ${linkerRouter.address}`);

    console.log(`Deploying Linker Router Proxy.`);
    const linkerRouterProxy = await deployContract(wallet, LinkerRouterProxy, [linkerRouter.address, wallet.address]);
    chain.linkerRouter = linkerRouterProxy.address;
    console.log(`Deployed at: ${linkerRouterProxy.address}`);

    setJSON(chains, `./info/${process.env.ENV}.json`);

    return new Contract(linkerRouterProxy.address, LinkerRouter.abi, wallet);
}

async function deployTokenService(chain, wallet) {
    const tokenService = await deployCreate3Upgradable(
        chain.create3Deployer,
        wallet,
        TokenService,
        TokenServiceProxy,
        [chain.gateway, chain.gasService, chain.linkerRouter, chain.tokenDeployer, chain.name],
        [],
        '0x',
        interchainTokenServiceKey,
    );
    return tokenService;
}

module.exports = {
    deployTokenDeployer,
    deployLinkerRouter,
    deployTokenService,
};
