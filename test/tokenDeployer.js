
'use strict';

const chai = require('chai');
const {
    getDefaultProvider,
    Contract,
    Wallet,
    constants: { AddressZero },
} = require('ethers');
const { expect } = chai;
const { keccak256, defaultAbiCoder } = require('ethers/lib/utils');
const { setJSON } = require('@axelar-network/axelar-local-dev/dist/utils');
require('dotenv').config();

const TokenDeployer = require('../artifacts/contracts/utils/TokenDeployer.sol/TokenDeployer.json');
const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const BytecodeServer = require('../artifacts/contracts/utils/BytecodeServer.sol/BytecodeServer.json');
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');
const IERC20MintableBurnable = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const TokenProxy = require('../artifacts/contracts/proxies/TokenProxy.sol/TokenProxy.json');
const { deployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/utils');
const { createAndExport, networks } = require('@axelar-network/axelar-local-dev');
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');

let chain;
let wallet;
let otherWallet;
let tokenDeployer;

async function setupLocal(toFund) {
    await createAndExport({
        chainOutputPath: './info/local.json',
        accountsToFund: toFund,
        relayInterval: 100,
        chains: ['Ethereum'],
    });
    chain = require('../info/local.json')[0];
}

before(async() => {
    const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
    const otherKey = keccak256(defaultAbiCoder.encode(['string'], ['another key']));
    const deployerAddress = new Wallet(deployerKey).address;
    const otherAddress = new Wallet(otherKey).address;
    const toFund = [deployerAddress, otherAddress];
    await setupLocal(toFund);
    const provider = getDefaultProvider(chain.rpc);
    wallet = new Wallet(deployerKey, provider);
    otherWallet = new Wallet(otherKey, provider);
    const { deployTokenDeployer } = require('../scripts/deploy.js');

    tokenDeployer = await deployTokenDeployer(chain, wallet);
});

describe('Token', () => {
    let token;
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `asdasdasd`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));
    const amount = 12345;

    before(async() => {
        await tokenDeployer.deployToken(name, symbol, decimals, wallet.address, salt);
        const deployer = new Contract(chain.create3Deployer, Create3Deployer.abi, wallet);
        const tokenAddress = await deployer.deployedAddress(tokenDeployer.address, salt);
        token = new Contract(tokenAddress, Token.abi, wallet);
    });

    it('Should Test that the token has the correct name, symbol, decimals and owner', async() => {
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
    });

    it('Should be able to mint as the owner', async() => {
        await token.mint(wallet.address, amount);

        expect(Number(await token.balanceOf(wallet.address))).to.equal(amount);
    });

    it('Should not be able to mint as not the owner', async() => {
        expect(token.connect(otherWallet).mint(wallet.address, amount)).to.be.revertedWith('NotOwner()');
    });

    it('Should not be able to burn as not the owner', async() => {
        await token.approve(otherWallet.address, amount);
        expect(token.connect(otherWallet).burnFrom(wallet.address, amount)).to.be.revertedWith('NotOwner()');
    });

    it('Should not be able to burn without approval', async() => {
        // This reverts because of integer underflow so we do not expect a specific error;
        expect(token.burnFrom(wallet.address, amount)).to.be.reverted;
    });
    it('Should be able to burn as the owner with approval', async() => {
        await token.approve(wallet.address, amount);
        await token.burnFrom(wallet.address, amount);
        
        expect(Number(await token.balanceOf(wallet.address))).to.equal(0);
    });
});