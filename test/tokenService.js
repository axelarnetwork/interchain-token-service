'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { AddressZero } = ethers.constants;
const { defaultAbiCoder, keccak256 } = ethers.utils;
const { Contract } = ethers;
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');

const TokenManager = require('../artifacts/contracts/tokenManager/TokenManager.sol/TokenManager.json');
const ERC20 = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');

const { approveContractCall, getRandomBytes32 } = require('../scripts/utils');
const { deployAll, deployContract } = require('../scripts/deploy');

const SELECTOR_SEND_TOKEN = 1;
// const SELECTOR_SEND_TOKEN_WITH_DATA = 2;
const SELECTOR_DEPLOY_TOKEN_MANAGER = 3;

const LOCK_UNLOCK = 0;
const MINT_BURN = 1;
const CANONICAL = 2;

describe('Interchain Token Service', () => {
    let wallet;
    let service, gateway, gasService;

    const deployFunctions = {};

    deployFunctions.lockUnlock = async function deployNewLockUnlock(tokenName, tokenSymbol, tokenDecimals, mintAmount = 0) {
        const salt = getRandomBytes32();
        const tokenId = await service.getCustomTokenId(wallet.address, salt);
        const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), TokenManager.abi, wallet);

        const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManager.address]);
        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

        await (await service.deployCustomTokenManager(salt, LOCK_UNLOCK, params)).wait();

        if (mintAmount > 0) {
            await (await token.mint(wallet.address, mintAmount)).wait();
            await (await token.approve(tokenManager.address, mintAmount)).wait();
        }

        return [token, tokenManager, tokenId];
    };

    deployFunctions.mintBurn = async function deployNewMintBurn(tokenName, tokenSymbol, tokenDecimals, mintAmount = 0) {
        const salt = getRandomBytes32();
        const tokenId = await service.getCustomTokenId(wallet.address, salt);
        const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
        const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);

        const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), TokenManager.abi, wallet);

        if (mintAmount > 0) {
            await (await token.mint(wallet.address, mintAmount)).wait();
        }

        await (await token.setDistributor(tokenManagerAddress)).wait();

        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
        await (await service.deployCustomTokenManager(salt, MINT_BURN, params)).wait();

        return [token, tokenManager, tokenId];
    };

    deployFunctions.canonical = async function deployNewCanonical(tokenName, tokenSymbol, tokenDecimals, mintAmount = 0) {
        const params = defaultAbiCoder.encode(
            ['bytes', 'string', 'string', 'uint8', 'uint256'],
            [wallet.address, tokenName, tokenSymbol, tokenDecimals, mintAmount],
        );
        const salt = getRandomBytes32();
        await (await service.deployCustomTokenManager(salt, CANONICAL, params)).wait();

        const tokenId = await service.getCustomTokenId(wallet.address, salt);
        const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
        const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
        const token = new Contract(tokenManagerAddress, ERC20.abi, wallet);

        return [token, tokenManager, tokenId];
    };

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];

        [service, gateway, gasService] = await deployAll(wallet, 'Test');
    });

    describe('Register Canonical Token', () => {
        let token;
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let tokenId;
        before(async () => {
            token = await deployContract(wallet, 'InterchainTokenTestCanonical', [tokenName, tokenSymbol, tokenDecimals, service.address]);
        });
        it('Should register a canonical token', async () => {
            const params = defaultAbiCoder.encode(['bytes', 'address'], [service.address, token.address]);
            tokenId = await service.getCanonicalTokenId(token.address);
            await expect(service.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(service.address);
        });
    });

    describe('Initiate Remote Canonical Token Deployment', () => {
        let token;
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let tokenId;
        before(async () => {
            token = await deployContract(wallet, 'InterchainTokenTestCanonical', [tokenName, tokenSymbol, tokenDecimals, service.address]);
            await (await service.registerCanonicalToken(token.address)).wait();
            tokenId = await service.getCanonicalTokenId(token.address);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
        });

        it('Should be able to initiate a remote canonical token deployment', async () => {
            const chains = ['chain1', 'chain2'];
            const gasValues = [1e6, 0];
            const params = defaultAbiCoder.encode(['bytes', 'string', ' string', 'uint8'], ['0x', tokenName, tokenSymbol, tokenDecimals]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, CANONICAL, params],
            );
            await expect(service.deployRemoteCanonicalTokens(tokenId, chains, gasValues, { value: 1e6 }))
                .to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[0], gasValues[0], CANONICAL, params)
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[1], gasValues[1], CANONICAL, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payload), payload)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[1], service.address.toLowerCase(), keccak256(payload), payload);
        });
    });

    describe('Register Canonical Token and Deploy Remote Tokens', async () => {
        let token;
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let tokenId;
        before(async () => {
            token = await deployContract(wallet, 'InterchainTokenTestCanonical', [tokenName, tokenSymbol, tokenDecimals, service.address]);
            tokenId = await service.getCanonicalTokenId(token.address);
        });

        it('Should be able to register a canonical token and initiate a remote canonical token deployment', async () => {
            const chains = ['chain1', 'chain2'];
            const gasValues = [1e6, 0];
            const originParams = defaultAbiCoder.encode(['bytes', 'address'], [service.address, token.address]);
            const remoteParams = defaultAbiCoder.encode(
                ['bytes', 'string', ' string', 'uint8'],
                ['0x', tokenName, tokenSymbol, tokenDecimals],
            );
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, CANONICAL, remoteParams],
            );
            tokenId = await service.getCanonicalTokenId(token.address);

            await expect(service.registerCanonicalTokenAndDeployRemoteCanonicalTokens(token.address, chains, gasValues, { value: 1e6 }))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, originParams)
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[0], gasValues[0], CANONICAL, remoteParams)
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[1], gasValues[1], CANONICAL, remoteParams)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payload), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payload), payload)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[1], service.address.toLowerCase(), keccak256(payload), payload);

            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(service.address);
        });
    });

    describe('Custom Token Manager Deploymenr', () => {
        it('Should deploy a lock/unlock token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            await expect(service.deployCustomTokenManager(salt, LOCK_UNLOCK, params))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(wallet.address);
        });

        it('Should deploy a mint/burn token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            await expect(service.deployCustomTokenManager(salt, MINT_BURN, params))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(wallet.address);
        });

        it('Should deploy a canonical token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const params = defaultAbiCoder.encode(
                ['bytes', 'string', 'string', 'uint8'],
                [wallet.address, tokenName, tokenSymbol, tokenDecimals],
            );

            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            await expect(service.deployCustomTokenManager(salt, CANONICAL, params))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, CANONICAL, params);

            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(wallet.address);
        });
    });

    describe('Initialize remote custom token manager deployment', () => {
        it('Should initialize a remote custom token manager deployment', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const chains = ['chain1', 'chain2'];
            const gasValues = [1e6, 0];
            const params = ['0x1234', '0x4567'];
            const types = [LOCK_UNLOCK, MINT_BURN];
            const payloads = [];

            for (const i of [0, 1]) {
                payloads.push(
                    defaultAbiCoder.encode(
                        ['uint256', 'bytes32', 'uint256', 'bytes'],
                        [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, types[i], params[i]],
                    ),
                );
            }

            await expect(service.deployRemoteCustomTokenManagers(salt, chains, types, params, gasValues, { value: 1e6 }))
                .to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[0], gasValues[0], types[0], params[0])
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[1], gasValues[1], types[1], params[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payloads[0]), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payloads[0]), payloads[0])
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[1], service.address.toLowerCase(), keccak256(payloads[1]), payloads[1]);
        });
    });

    describe('Deploy custom token manager and initialize remote custom token manager deployment', () => {
        let salt;
        let tokenManagerType;
        let params;
        it('Should deploy a lock/unlock token manager', async () => {
            tokenManagerType = LOCK_UNLOCK;

            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);

            params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
        });

        it('Should deploy a mint/burn token manager', async () => {
            tokenManagerType = MINT_BURN;

            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
        });

        it('Should deploy a canonical token manager', async () => {
            tokenManagerType = CANONICAL;

            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;

            params = defaultAbiCoder.encode(
                ['bytes', 'string', 'string', 'uint8'],
                [wallet.address, tokenName, tokenSymbol, tokenDecimals],
            );
            salt = getRandomBytes32();
        });

        afterEach('Should initialize a remote custom token manager deployment', async () => {
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const chains = ['chain1', 'chain2'];
            const gasValues = [1e6, 0];
            const remoteParams = ['0x1234', '0x4567'];
            const types = [LOCK_UNLOCK, MINT_BURN];
            const payloads = [];

            for (const i of [0, 1]) {
                payloads.push(
                    defaultAbiCoder.encode(
                        ['uint256', 'bytes32', 'uint256', 'bytes'],
                        [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, types[i], remoteParams[i]],
                    ),
                );
            }

            await expect(
                service.deployCustomTokenManagerAndDeployRemote(salt, tokenManagerType, params, chains, types, remoteParams, gasValues, {
                    value: 1e6,
                }),
            )
                .to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[0], gasValues[0], types[0], remoteParams[0])
                .and.to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, chains[1], gasValues[1], types[1], remoteParams[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payloads[0]), gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[0], service.address.toLowerCase(), keccak256(payloads[0]), payloads[0])
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, chains[1], service.address.toLowerCase(), keccak256(payloads[1]), payloads[1]);

            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.admin()).to.equal(wallet.address);
        });
    });

    describe('Receive Remote Token Manager Deployment', () => {
        const sourceChain = 'source chain';
        let sourceAddress;
        before(async () => {
            sourceAddress = service.address.toLowerCase();
        });

        it('Should be able to receive a remote lock/unlock token manager depoloyment', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, LOCK_UNLOCK, params],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(token.address);
            expect(await tokenManager.admin()).to.equal(wallet.address);
        });

        it('Should be able to receive a remote lock/unlock token manager depoloyment', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, MINT_BURN, params],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(token.address);
            expect(await tokenManager.admin()).to.equal(wallet.address);
        });

        it('Should be able to receive a remote canonical token manager depoloyment', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const tokenId = getRandomBytes32();
            const params = defaultAbiCoder.encode(
                ['bytes', 'string', ' string', 'uint8', 'uint256'],
                [wallet.address, tokenName, tokenSymbol, tokenDecimals, 0],
            );
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, CANONICAL, params],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, CANONICAL, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenManagerAddress);
            expect(await tokenManager.admin()).to.equal(wallet.address);
        });
    });

    describe('SendToken', () => {
        const amount = 1234;
        const destChain = 'destination Chain';
        const destAddress = '0x5678';
        const gasValue = 90;

        for (const type of ['lockUnlock', 'mintBurn', 'canonical']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount);

                let sendHash;
                let payloadHash;

                function checkSendHash(hash) {
                    return sendHash === hash;
                }

                function checkPayloadHash(hash) {
                    return payloadHash === hash;
                }

                function checkPayload(payload) {
                    const emmitted = defaultAbiCoder.decode(['uint256', 'bytes32', 'bytes', 'uint256', 'bytes32'], payload);

                    if (Number(emmitted[0]) !== SELECTOR_SEND_TOKEN) return false;
                    if (emmitted[1] !== tokenId) return false;
                    if (emmitted[2] !== destAddress) return false;
                    if (Number(emmitted[3]) !== amount) return false;
                    sendHash = emmitted[4];
                    payloadHash = keccak256(payload);
                    return true;
                }

                const transferToAddress = type === 'lockUnlock' ? tokenManager.address : AddressZero;
                await expect(tokenManager.sendToken(destChain, destAddress, amount, { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destChain, service.address.toLowerCase(), anyValue, checkPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destChain, service.address.toLowerCase(), checkPayloadHash, gasValue, wallet.address)
                    .to.emit(service, 'TokenSent')
                    .withArgs(tokenId, destChain, destAddress, amount, checkSendHash);
            });
        }
    });

    describe('Receive Remote Tokens', () => {
        const sourceChain = 'source chain';
        let sourceAddress;
        const amount = 1234;
        let destAddress;
        before(async () => {
            sourceAddress = service.address.toLowerCase();
            destAddress = wallet.address;
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount);
            (await await token.transfer(tokenManager.address, amount)).wait();
            const sendHash = getRandomBytes32();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes32'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount, sendHash],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount, sendHash);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(`Test Token Mint Burn`, 'TT', 12, amount);

            const sendHash = getRandomBytes32();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes32'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount, sendHash],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount, sendHash);
        });

        it('Should be able to receive canonical token', async () => {
            const [token, , tokenId] = await deployFunctions.canonical(`Test Token Lock Unlock}`, 'TT', 12, amount);

            const sendHash = getRandomBytes32();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes32'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount, sendHash],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount, sendHash);
        });
    });

    describe('Flow Limits', () => {
        const destinationChain = 'dest';
        const destinationAddress = '0x1234';
        let tokenManager, tokenId;
        const sendAmount = 1234;
        const flowLimit = (sendAmount * 3) / 2;
        const mintAmount = flowLimit * 3;
        beforeEach(async () => {
            [, tokenManager, tokenId] = await deployFunctions.canonical(`Test Token Lock Unlock`, 'TT', 12, mintAmount);
            await (await tokenManager.setFlowLimit(flowLimit)).wait();
        });

        // These tests will fail every once in a while since the two transactions will happen in different epochs.
        // LMK of any fixes to this that do not involve writing a new contract to facilitate a multicall.
        it('Should be able to send token only if it does not trigger the mint limit', async () => {
            await (await tokenManager.sendToken(destinationChain, destinationAddress, sendAmount)).wait();
            await expect(tokenManager.sendToken(destinationChain, destinationAddress, sendAmount)).to.be.revertedWithCustomError(
                tokenManager,
                'FlowLimitExceeded',
            );
        });

        it('Should be able to receive token only if it does not trigger the mint limit', async () => {
            async function receiveToken(sendAmount) {
                const sendHash = getRandomBytes32();

                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes32'],
                    [SELECTOR_SEND_TOKEN, tokenId, wallet.address, sendAmount, sendHash],
                );
                const commandId = await approveContractCall(gateway, destinationChain, service.address, service.address, payload);

                return service.execute(commandId, destinationChain, service.address, payload);
            }

            await (await receiveToken(sendAmount)).wait();

            await expect(receiveToken(sendAmount)).to.be.revertedWithCustomError(tokenManager, 'FlowLimitExceeded');
        });
    });
});
