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
    await deployTokenDeployer(chain, wallet);
    tokenService = await deployTokenService(chain, wallet);
});

describe('TokenService', () => {
    let token;
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `asdasdasd`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));

    before(async () => {});

    it('Should be able to deploy a native interchain token', async () => {
        const deploymentAddress = await tokenService.getDeploymentAddress(wallet.address, salt);
        // const tokenId = await tokenService.getOriginTokenId(deploymentAddress);
        await tokenService.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], []);
        token = new Contract(deploymentAddress, Token.abi, wallet);
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.owner()).to.equal(wallet.address);
    });
});
