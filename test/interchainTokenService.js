'use strict';

const chai = require('chai');
const { getDefaultProvider, Contract, Wallet } = require('ethers');
const { expect } = chai;
const { keccak256, defaultAbiCoder } = require('ethers/lib/utils');
require('dotenv').config();
const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const ITokenService = require('../artifacts/contracts/interfaces/IInterchainTokenService.sol/IInterchainTokenService.json');

const { createAndExport } = require('@axelar-network/axelar-local-dev');

let chain;
let chains;
let wallet;
let tokenService;
let tokenDeployer;

async function setupLocal(toFund) {
    await createAndExport({
        chainOutputPath: './info/local.json',
        accountsToFund: toFund,
        relayInterval: 100,
        chains: ['Ethereum', 'Moonbeam', 'Avalanche'],
        port: 8502,
    });
    chains = require('../info/local.json');
    chain = chains[0];
}

async function waitForAxelar(numberOfHops = 1) {
    await new Promise((resolve) => {
        setTimeout(resolve, numberOfHops * 500);
    });
}

before(async () => {
    const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
    const deployerAddress = new Wallet(deployerKey).address;
    const toFund = [deployerAddress];
    await setupLocal(toFund);
    tokenDeployer = [];
    tokenService = [];
    const provider = getDefaultProvider(chain.rpc);
    wallet = new Wallet(deployerKey, provider);
    for(const chain of chains) {
        const provider = getDefaultProvider(chain.rpc);
        const wallet = new Wallet(deployerKey, provider);
        const { deployTokenService, deployLinkerRouter, deployTokenDeployer } = require('../scripts/deploy.js');
        await deployLinkerRouter(chain, wallet);
        tokenDeployer.push(await deployTokenDeployer(chain, wallet));
        tokenService.push(await deployTokenService(chain, wallet));
    }
    tokenDeployer = tokenDeployer[0];
    tokenService = tokenService[0];
});

describe('TokenService', () => {
    let token;
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `tokenServiceKey`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));
    let tokenAddress;
    let tokenId;

    before(async () => {
        tokenAddress = await tokenDeployer.getDeploymentAddress(tokenDeployer.address, salt);
        tokenId = await tokenService.getOriginTokenId(tokenAddress);
    });

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
        token = new Contract(tokenAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
        await tokenService.registerOriginToken(tokenAddress);

        expect(await tokenService.getTokenId(tokenAddress)).to.equal(tokenId);
        expect(await tokenService.getTokenAddress(tokenId)).to.equal(tokenAddress);
    });
    it('Should be not able to register an origin token that has already been registered', async () => {
        await expect(tokenService.registerOriginToken(tokenAddress)).to.be.reverted;
    });
    it('Should be able to deploy a remote token for the origin token', async() => {
        const destinationChains = [chains[1].name, chains[2].name];
        const gasValues = [1e7, 1e7];
        await tokenService.deployRemoteTokens(tokenId, destinationChains, gasValues, {value: 2e7});

        await waitForAxelar();

        for(let i of [1, 2]) {
            const remoteChain = chains[i];
            const remoteProvider = getDefaultProvider(remoteChain.rpc);
            const remoteWallet = wallet.connect(remoteProvider);
            const remoteTokenService = new Contract(remoteChain.interchainTokenService, ITokenService.abi, remoteWallet);
            const remoteTokenAddress = await remoteTokenService.getTokenAddress(tokenId);
            expect(remoteTokenAddress).to.not.equal(AddressZero);
            expect(await remoteTokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
        }
    })
});
