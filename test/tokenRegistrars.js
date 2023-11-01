'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { defaultAbiCoder, keccak256 } = ethers.utils;
const {
    Contract,
    constants: { AddressZero },
} = ethers;

const ITokenManager = require('../artifacts/contracts/interfaces/ITokenManager.sol/ITokenManager.json');
const IERC20 = require('../artifacts/@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol/IERC20.json');

const { deployAll, deployContract } = require('../scripts/deploy');

// const SELECTOR_SEND_TOKEN_WITH_DATA = 2;
// const SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
const SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;

const LOCK_UNLOCK = 2;
const MINT_BURN = 0;

// const DISTRIBUTOR_ROLE = 0;
const OPERATOR_ROLE = 1;

describe('Token Registrsrs', () => {
    let wallet;
    let service, gateway, gasService, canonicalTokenRegistrar, standardizedTokenRegistrar;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        [service, gateway, gasService] = await deployAll(wallet, 'Test', [destinationChain]);
        let proxy, factory;

        canonicalTokenRegistrar = await deployContract(wallet, 'CanonicalTokenRegistrar', [service.address]);
        proxy = await deployContract(wallet, 'CanonicalTokenRegistrarProxy', [canonicalTokenRegistrar.address, wallet.address]);
        factory = await ethers.getContractFactory('CanonicalTokenRegistrar', wallet);
        canonicalTokenRegistrar = factory.attach(proxy.address);

        standardizedTokenRegistrar = await deployContract(wallet, 'StandardizedTokenRegistrar', [service.address]);
        proxy = await deployContract(wallet, 'StandardizedTokenRegistrarProxy', [standardizedTokenRegistrar.address, wallet.address]);
        factory = await ethers.getContractFactory('StandardizedTokenRegistrar', wallet);
        standardizedTokenRegistrar = factory.attach(proxy.address);
    });

    describe('Canonical Token Registrar', async () => {
        let token, tokenId, tokenManagerAddress;
        const tokenCap = BigInt(1e18);

        async function deployToken() {
            token = await deployContract(wallet, 'InterchainTokenTest', [name, symbol, decimals, wallet.address]);
            tokenId = await canonicalTokenRegistrar.getCanonicalTokenId(token.address);
            tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenManager(tokenManagerAddress)).wait();
        }

        it('Should register a token', async () => {
            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(canonicalTokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
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
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            await expect(
                canonicalTokenRegistrar.deployAndRegisterRemoteCanonicalToken(salt, destinationChain, gasValue, { value: gasValue }),
            )
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, '0x', destinationChain, gasValue)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should transfer some tokens though the registrar as the deployer', async () => {
            const destinationAddress = '0x659703';
            const amount = 1234;
            const gasValue = 1234;

            await deployToken();

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(canonicalTokenRegistrar.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

            tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);

            await (await token.approve(canonicalTokenRegistrar.address, amount)).wait();

            await expect(
                canonicalTokenRegistrar.transferCanonicalToken(token.address, destinationChain, destinationAddress, amount, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'TokenSent')
                .withArgs(tokenId, destinationChain, destinationAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(wallet.address, canonicalTokenRegistrar.address, amount)
                .to.emit(token, 'Transfer')
                .withArgs(canonicalTokenRegistrar.address, tokenManagerAddress, amount);
        });
    });

    describe('Standardized Token Registrar', async () => {
        let tokenId;
        const mintAmount = 1234;

        it('Should register a token', async () => {
            const salt = keccak256('0x');
            tokenId = await standardizedTokenRegistrar.getStandardizedTokenId(wallet.address, salt);
            const tokenAddress = await standardizedTokenRegistrar.getStandardizedTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [standardizedTokenRegistrar.address, tokenAddress]);
            const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IERC20.abi, wallet);
            await expect(standardizedTokenRegistrar.deployStandardizedToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenAddress, wallet.address, name, symbol, decimals, mintAmount, standardizedTokenRegistrar.address)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(standardizedTokenRegistrar.address, wallet.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(standardizedTokenRegistrar.address, 1 << OPERATOR_ROLE);
        });

        it('Should initiate a remote standardized token deployment with the same distributor', async () => {
            const gasValue = 1234;
            const mintAmount = 5678;

            const salt = keccak256('0x12');
            tokenId = await standardizedTokenRegistrar.getStandardizedTokenId(wallet.address, salt);
            const tokenAddress = await standardizedTokenRegistrar.getStandardizedTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [standardizedTokenRegistrar.address, tokenAddress]);
            const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IERC20.abi, wallet);
            await expect(standardizedTokenRegistrar.deployStandardizedToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenAddress, wallet.address, name, symbol, decimals, mintAmount, standardizedTokenRegistrar.address)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(standardizedTokenRegistrar.address, wallet.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(standardizedTokenRegistrar.address, 1 << OPERATOR_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    name,
                    symbol,
                    decimals,
                    wallet.address.toLowerCase(),
                    '0x',
                    mintAmount,
                    wallet.address.toLowerCase(),
                ],
            );

            await expect(
                standardizedTokenRegistrar.deployRemoteStandarizedToken(
                    salt,
                    wallet.address,
                    wallet.address,
                    mintAmount,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            )
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(
                    tokenId,
                    name,
                    symbol,
                    decimals,
                    wallet.address.toLowerCase(),
                    '0x',
                    mintAmount,
                    wallet.address.toLowerCase(),
                    destinationChain,
                    gasValue,
                )
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should initiate a remote standardized token deployment without the same distributor', async () => {
            const gasValue = 1234;

            const salt = keccak256('0x1245');
            tokenId = await standardizedTokenRegistrar.getStandardizedTokenId(wallet.address, salt);
            const tokenAddress = await standardizedTokenRegistrar.getStandardizedTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [standardizedTokenRegistrar.address, tokenAddress]);
            const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IERC20.abi, wallet);
            await expect(standardizedTokenRegistrar.deployStandardizedToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenAddress, wallet.address, name, symbol, decimals, mintAmount, standardizedTokenRegistrar.address)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(standardizedTokenRegistrar.address, wallet.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(standardizedTokenRegistrar.address, 1 << OPERATOR_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    name,
                    symbol,
                    decimals,
                    '0x',
                    '0x',
                    0,
                    wallet.address.toLowerCase(),
                ],
            );

            await expect(
                standardizedTokenRegistrar.deployRemoteStandarizedToken(salt, AddressZero, wallet.address, 0, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, name, symbol, decimals, '0x', '0x', 0, wallet.address.toLowerCase(), destinationChain, gasValue)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should fail initiate a remote standardized token deployment without the same distributor with a mintAmount', async () => {
            const gasValue = 1234;
            const mintAmount = 5678;

            const salt = keccak256('0x124567');
            tokenId = await standardizedTokenRegistrar.getStandardizedTokenId(wallet.address, salt);
            const tokenAddress = await standardizedTokenRegistrar.getStandardizedTokenAddress(wallet.address, salt);
            let params = defaultAbiCoder.encode(['bytes', 'address'], [standardizedTokenRegistrar.address, tokenAddress]);
            const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), ITokenManager.abi, wallet);
            const token = new Contract(tokenAddress, IERC20.abi, wallet);
            await expect(standardizedTokenRegistrar.deployStandardizedToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenAddress, wallet.address, name, symbol, decimals, mintAmount, standardizedTokenRegistrar.address)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(standardizedTokenRegistrar.address, wallet.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(standardizedTokenRegistrar.address, 1 << OPERATOR_ROLE);

            params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(
                standardizedTokenRegistrar.deployRemoteStandarizedToken(
                    salt,
                    AddressZero,
                    wallet.address,
                    mintAmount,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            ).to.be.revertedWithCustomError(standardizedTokenRegistrar, 'NonZeroMintAmount');
        });
    });
});
