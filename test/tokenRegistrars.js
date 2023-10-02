'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256 } = ethers.utils;
const { Contract, Wallet } = ethers;

const IStandardizedToken = require('../artifacts/contracts/interfaces/IStandardizedToken.sol/IStandardizedToken.json');
const ITokenManager = require('../artifacts/contracts/interfaces/ITokenManager.sol/ITokenManager.json');

const { getRandomBytes32 } = require('../scripts/utils');
const { deployAll, deployContract } = require('../scripts/deploy');

const SELECTOR_SEND_TOKEN = 1;
// const SELECTOR_SEND_TOKEN_WITH_DATA = 2;
// const SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
const SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

const LOCK_UNLOCK = 0;
const MINT_BURN = 1;
// const LIQUIDITY_POOL = 2;

describe.only('Token Registrsrs', () => {
    let wallet;
    let service, gateway, gasService, canonicalTokenRegistrar;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService] = await deployAll(wallet, 'Test', [destinationChain]);
        canonicalTokenRegistrar = await deployContract(wallet, 'CanonicalTokenRegistrar', [service.address, 'chain name']);

    });

    describe('Canonical Token Registrar', async () => {
        let token, tokenId, tokenManager;
        const tokenCap = BigInt(1e18);

        async function deployToken() {
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);
            tokenId = await canonicalTokenRegistrar.getCanonicalTokenId(token.address);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
            tokenManager = new Contract(tokenManagerAddress, ITokenManager.abi, wallet);
        }


        it('Should register a token', async () => {
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(canonicalTokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params)

        });

        it('Should initiate a remote standardized token deployment', async () => {
            const gasValue = 1234;

            await deployToken();

            const salt = await canonicalTokenRegistrar.getCanonicalTokenSalt(token.address);
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, name, symbol, decimals, '0x', '0x', 0, '0x'],
            );

            await expect(canonicalTokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params)

            await expect(canonicalTokenRegistrar.deployAndRegisterRemoteCanonicalToken(salt, destinationChain, gasValue, { value: gasValue }))
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, '0x', destinationChain, gasValue)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });
    });

});
