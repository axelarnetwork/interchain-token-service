'use strict';

const chai = require('chai');
const { getDefaultProvider, Contract, Wallet } = require('ethers');
const { expect } = chai;
const { keccak256, defaultAbiCoder } = require('ethers/lib/utils');
require('dotenv').config();
const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');

const { createAndExport } = require('@axelar-network/axelar-local-dev');

let chain;
let wallet;
let tokenService;
let tokenDeployer;

async function setupLocal(toFund) {
    await createAndExport({
        chainOutputPath: './info/local.json',
        accountsToFund: toFund,
        relayInterval: 100,
        chains: ['Ethereum'],
        port: 8502,
    });
    chain = require('../info/local.json')[0];
}

before(async () => {
    const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
    const deployerAddress = new Wallet(deployerKey).address;
    const toFund = [deployerAddress];
    await setupLocal(toFund);
    const provider = getDefaultProvider(chain.rpc);
    wallet = new Wallet(deployerKey, provider);
    const { deployTokenService, deployLinkerRouter, deployTokenDeployer } = require('../scripts/deploy.js');
    await deployLinkerRouter(chain, wallet);
    tokenDeployer = await deployTokenDeployer(chain, wallet);
    tokenService = await deployTokenService(chain, wallet);
});

describe('TokenService', () => {
    let token;
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `tokenServiceKey`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));

    before(async () => {});

    it('Should be able to deploy a native interchain token', async () => {
        const deploymentAddress = await tokenService.getDeploymentAddress(wallet.address, salt);
        const tokenId = await tokenService.getOriginTokenId(deploymentAddress);
        await tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], []);
        token = new Contract(deploymentAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
        expect(await tokenService.getTokenId(deploymentAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(deploymentAddress);
    });
    it('Should be not able to register an origin token that does not exist', async () => {
        const tokenAddress = await tokenDeployer.getDeploymentAddress(tokenDeployer.address, salt);

        await expect(tokenService.registerOriginToken(tokenAddress)).to.be.reverted;
    });
    it('Should be able to register an origin token', async () => {
        await tokenDeployer.deployToken(name, symbol, decimals, wallet.address, salt);
        const tokenAddress = await tokenDeployer.getDeploymentAddress(tokenDeployer.address, salt);
        token = new Contract(tokenAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
        const tokenId = await tokenService.getOriginTokenId(tokenAddress);
        await tokenService.registerOriginToken(tokenAddress);

        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);
    });
    it('Should be not able to register an origin token that has already been registered', async () => {
        const tokenAddress = await tokenDeployer.getDeploymentAddress(tokenDeployer.address, salt);
        await expect(tokenService.registerOriginToken(tokenAddress)).to.be.reverted;
    });
});
