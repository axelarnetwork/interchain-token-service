'use strict';

require('dotenv').config();

const TokenDeployer = require('../artifacts/contracts/utils/TokenDeployer.sol/TokenDeployer.json');

const BytecodeServer = require('../artifacts/contracts/utils/BytecodeServer.sol/BytecodeServer.json');
const Token = require('../artifacts/contracts/utils/ERC20BurnableMintable.sol/ERC20BurnableMintable.json');
const TokenProxy = require('../artifacts/contracts/proxies/TokenProxy.sol/TokenProxy.json');
const { deployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/utils');
const { setJSON } = require('@axelar-network/axelar-local-dev');
const { deployCreate3Contract } = require('@axelar-network/axelar-gmp-sdk-solidity');
const chains = require(`../info/${process.env.ENV}.json`);

async function deployTokenDeployer(chain, wallet) {
    if (chain.tokenDeployer) return;

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

async function deployTokenLinker(chain, wallet) {
    await deployCreate3Contract(chain.create3Deployer, wallet, InterchainTokenService, 'interchainTokenService', [
        chain.gateway,
        chain.gaswService,
        address linkerRouterAddress_,
        chain.tokenDeployer,
        chain.name,
    ])
}

module.exports = {
    deployTokenDeployer,
};
