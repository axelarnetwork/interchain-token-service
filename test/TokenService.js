'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { AddressZero, MaxUint256 } = ethers.constants;
const { defaultAbiCoder, solidityPack, keccak256, arrayify } = ethers.utils;
const { Contract, Wallet } = ethers;
const TokenManager = require('../artifacts/contracts/token-manager/TokenManager.sol/TokenManager.json');
const Token = require('../artifacts/contracts/interfaces/IStandardizedToken.sol/IStandardizedToken.json');
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { approveContractCall } = require('../scripts/utils');
const { getRandomBytes32, expectRevert } = require('./utils');
const {
    deployAll,
    deployContract,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployRemoteAddressValidator,
    deployTokenManagerImplementations,
} = require('../scripts/deploy');

const SELECTOR_SEND_TOKEN = 1;
const SELECTOR_SEND_TOKEN_WITH_DATA = 2;
const SELECTOR_DEPLOY_TOKEN_MANAGER = 3;
const SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN = 4;
const INVALID_SELECTOR = 5;

const MINT_BURN = 0;
const MINT_BURN_FROM = 1;
const LOCK_UNLOCK = 2;
const LOCK_UNLOCK_FEE_ON_TRANSFER = 3;

// const DISTRIBUTOR_ROLE = 1;
const OPERATOR_ROLE = 2;
const FLOW_LIMITER_ROLE = 3;

describe('Interchain Token Service', () => {
    let wallet, otherWallet;
    let service, gateway, gasService;

    const deployFunctions = {};
    const destinationChain = 'destination chain';
    const sourceChain = 'source chain';

    deployFunctions.lockUnlock = async function deployNewLockUnlock(
        tokenName,
        tokenSymbol,
        tokenDecimals,
        mintAmount = 0,
        skipApprove = false,
    ) {
        const salt = getRandomBytes32();
        const tokenId = await service.getCustomTokenId(wallet.address, salt);
        const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), TokenManager.abi, wallet);

        const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManager.address]);
        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

        await (await service.deployCustomTokenManager(salt, LOCK_UNLOCK, params)).wait();

        if (mintAmount > 0) {
            await (await token.mint(wallet.address, mintAmount)).wait();
            if (!skipApprove) await (await token.approve(tokenManager.address, mintAmount)).wait();
        }

        return [token, tokenManager, tokenId];
    };

    deployFunctions.lockUnlockFee = async function deployNewLockUnlock(
        tokenName,
        tokenSymbol,
        tokenDecimals,
        mintAmount = 0,
        skipApprove = false,
    ) {
        const salt = getRandomBytes32();
        const tokenId = await service.getCustomTokenId(wallet.address, salt);
        const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), TokenManager.abi, wallet);

        const token = await deployContract(wallet, 'FeeOnTransferTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManager.address]);
        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

        await (await service.deployCustomTokenManager(salt, LOCK_UNLOCK_FEE_ON_TRANSFER, params)).wait();

        if (mintAmount > 0) {
            await token.mint(wallet.address, mintAmount).then((tx) => tx.wait());

            if (!skipApprove) {
                await token.approve(tokenManager.address, mintAmount).then((tx) => tx.wait());
            }
        }

        return [token, tokenManager, tokenId];
    };

    const makeDeployNewMintBurn = (type) =>
        async function deployNewMintBurn(tokenName, tokenSymbol, tokenDecimals, mintAmount = 0) {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);

            const tokenManager = new Contract(await service.getTokenManagerAddress(tokenId), TokenManager.abi, wallet);

            if (mintAmount > 0) {
                await (await token.mint(wallet.address, mintAmount)).wait();
            }

            await (await token.transferDistributorship(tokenManagerAddress)).wait();

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            await (await service.deployCustomTokenManager(salt, type, params)).wait();

            return [token, tokenManager, tokenId];
        };

    deployFunctions.mintBurn = makeDeployNewMintBurn(MINT_BURN);
    deployFunctions.mintBurnFrom = makeDeployNewMintBurn(MINT_BURN_FROM);

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        otherWallet = wallets[1];
        [service, gateway, gasService] = await deployAll(wallet, 'Test', [sourceChain, destinationChain]);
    });

    describe('Interchain Token Service Deployment', () => {
        let create3Deployer;
        let gateway;
        let gasService;
        let tokenManagerDeployer;
        let standardizedToken;
        let standardizedTokenDeployer;
        let interchainTokenServiceAddress;
        let remoteAddressValidator;
        let tokenManagerImplementations;

        const chainName = 'Test';
        const deploymentKey = 'interchainTokenService';

        before(async () => {
            create3Deployer = await deployContract(wallet, 'Create3Deployer');
            gateway = await deployMockGateway(wallet);
            gasService = await deployGasService(wallet);
            tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
            standardizedToken = await deployContract(wallet, 'StandardizedToken');
            standardizedTokenDeployer = await deployContract(wallet, 'StandardizedTokenDeployer', [standardizedToken.address]);
            interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
            remoteAddressValidator = await deployRemoteAddressValidator(wallet, interchainTokenServiceAddress, chainName);
            tokenManagerImplementations = await deployTokenManagerImplementations(wallet, interchainTokenServiceAddress);
        });

        it('Should revert on invalid remote address validator', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        AddressZero,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid gas service', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        AddressZero,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid token manager deployer', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        AddressZero,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid standardized token deployer', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        AddressZero,
                        gateway.address,
                        gasService.address,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid gateway', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        AddressZero,
                        gasService.address,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid token manager implementation length', async () => {
            tokenManagerImplementations.push(wallet);

            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'LengthMismatch',
            );

            tokenManagerImplementations.pop();
        });

        it('Should return all token manager implementations', async () => {
            const service = await deployInterchainTokenService(
                wallet,
                create3Deployer.address,
                tokenManagerDeployer.address,
                standardizedTokenDeployer.address,
                gateway.address,
                gasService.address,
                remoteAddressValidator.address,
                tokenManagerImplementations.map((impl) => impl.address),
                deploymentKey,
            );

            const length = tokenManagerImplementations.length;
            let implementation;

            for (let i = 0; i < length; i++) {
                implementation = await service.getImplementation(i);
                expect(implementation).to.eq(tokenManagerImplementations[i].address);
            }

            await expectRevert((gasOptions) => service.getImplementation(length, gasOptions), service, 'InvalidImplementation');
        });

        it('Should revert on invalid token manager implementation', async () => {
            const toRemove = tokenManagerImplementations.pop();

            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        remoteAddressValidator.address,
                        [...tokenManagerImplementations.map((impl) => impl.address), AddressZero],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );

            tokenManagerImplementations.push(toRemove);
        });

        it('Should revert on duplicate token manager type', async () => {
            const length = tokenManagerImplementations.length;
            tokenManagerImplementations[length - 1] = tokenManagerImplementations[length - 2];

            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        standardizedTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        remoteAddressValidator.address,
                        tokenManagerImplementations.map((impl) => impl.address),
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'InvalidTokenManagerImplementation',
            );
        });

        it('Should revert if setup fails on TokenManager implementation deployment', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const validParams = defaultAbiCoder.encode(['bytes', 'address'], ['0x', wallet.address]);
            const tokenManagerProxy = await deployContract(wallet, `TokenManagerProxy`, [
                service.address,
                LOCK_UNLOCK,
                tokenId,
                validParams,
            ]);
            const invalidParams = '0x1234';

            await expectRevert(
                (gasOptions) =>
                    deployContract(wallet, `TokenManagerProxy`, [service.address, LOCK_UNLOCK, tokenId, invalidParams, gasOptions]),
                tokenManagerProxy,
                'SetupFailed',
            );
        });
    });

    describe('Register Canonical Token', () => {
        let token;
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let tokenId;
        let txPaused;

        beforeEach(async () => {
            token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, service.address]);
            tokenId = await service.getCanonicalTokenId(token.address);
            await (await token.setTokenManager(await service.getTokenManagerAddress(tokenId))).wait();

            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should revert on pausing if not the owner', async () => {
            await expectRevert((gasOptions) => service.connect(otherWallet).setPaused(true, gasOptions), service, 'NotOwner');
        });

        it('Should revert on get token manager if token manager does not exist', async () => {
            await expectRevert(
                (gasOptions) => service.getValidTokenManagerAddress(tokenId, gasOptions),
                service,
                'TokenManagerDoesNotExist',
            );
        });

        it('Should register a canonical token', async () => {
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            await expect(service.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should revert if canonical token has already been registered', async () => {
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);
            await expect(service.registerCanonicalToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, LOCK_UNLOCK, params);

            await expectRevert(
                (gasOptions) => service.registerCanonicalToken(token.address, gasOptions),
                service,
                'TokenManagerDeploymentFailed',
            );
        });

        it('Should revert when trying to register a gateway token', async () => {
            await (await gateway.setTokenAddress(tokenSymbol, token.address)).wait();
            await expectRevert((gasOptions) => service.registerCanonicalToken(token.address, gasOptions), service, 'GatewayToken');
        });

        it('Should revert when registering a canonical token if paused', async () => {
            let tx = await service.setPaused(true);
            await tx.wait();
            await expectRevert((gasOptions) => service.registerCanonicalToken(token.address, gasOptions), service, 'Paused');
            tx = await service.setPaused(false);
            await tx.wait();
        });
    });

    describe('Initiate Remote Canonical Token Deployment', () => {
        let token;
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let tokenId;
        let txPaused;

        beforeEach(async () => {
            token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, service.address]);
            await service.registerCanonicalToken(token.address).then((tx) => tx.wait());

            tokenId = await service.getCanonicalTokenId(token.address);
            await token.setTokenManager(await service.getTokenManagerAddress(tokenId)).then((tx) => tx.wait());

            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);

            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should be able to initiate a remote standardized token deployment', async () => {
            const gasValue = 1e6;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, '0x', '0x', 0, '0x'],
            );
            await expect(service.deployRemoteCanonicalToken(tokenId, destinationChain, gasValue, { value: gasValue }))
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(tokenId, tokenName, tokenSymbol, tokenDecimals, '0x', '0x', 0, '0x', destinationChain, gasValue)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should revert if token manager for given tokenID is not a canonical token manager', async () => {
            const tokenName = 'Standardized Token';
            const tokenSymbol = 'ST';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const mintAmount = 123456;

            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
            await expect(
                service.deployAndRegisterStandardizedToken(salt, tokenName, tokenSymbol, tokenDecimals, mintAmount, wallet.address),
            )
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);

            const gasValue = 1e6;
            await expectRevert(
                (gasOptions) => service.deployRemoteCanonicalToken(tokenId, destinationChain, gasValue, { ...gasOptions, value: gasValue }),
                service,
                'NotCanonicalTokenManager',
            );
        });

        it('Should revert on remote standardized token deployment if paused', async () => {
            let tx = await service.setPaused(true);
            await tx.wait();

            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const gasValue = 1e6;

            await expectRevert(
                (gasOptions) => service.deployRemoteCanonicalToken(tokenId, destinationChain, gasValue, { ...gasOptions, value: gasValue }),
                service,
                'Paused',
            );

            tx = await service.setPaused(false);
            await tx.wait();
        });
    });

    describe('Deploy and Register Standardized Token', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        const mintAmount = 123456;
        let txPaused;

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should register a standardized token', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
            await expect(
                service.deployAndRegisterStandardizedToken(salt, tokenName, tokenSymbol, tokenDecimals, mintAmount, wallet.address),
            )
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should revert when registering a standardized token when service is paused', async () => {
            const salt = getRandomBytes32();

            txPaused = await service.setPaused(true);
            await txPaused.wait();

            await expectRevert(
                (gasOptions) =>
                    service.deployAndRegisterStandardizedToken(
                        salt,
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        mintAmount,
                        wallet.address,
                        gasOptions,
                    ),
                service,
                'Paused',
            );

            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should revert when registering a standardized token as a lock/unlock for a second time', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
            await expect(
                service.deployAndRegisterStandardizedToken(salt, tokenName, tokenSymbol, tokenDecimals, mintAmount, wallet.address),
            )
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManagerAddress = await service.getValidTokenManagerAddress(tokenId);
            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

            // Register the same token again
            await expectRevert(
                (gasOptions) =>
                    service.deployAndRegisterStandardizedToken(
                        salt,
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        mintAmount,
                        wallet.address,
                        gasOptions,
                    ),
                service,
                'StandardizedTokenDeploymentFailed',
            );
        });
    });

    describe('Deploy and Register remote Standardized Token', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        const distributor = '0x12345678';
        const mintTo = '0x0abc';
        const mintAmount = 123456;
        const operator = '0x5678';
        const gasValue = 1234;
        const salt = getRandomBytes32();
        let txPaused;

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should initialize a remote standardized token deployment', async () => {
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );
            await expect(
                service.deployAndRegisterRemoteStandardizedToken(
                    salt,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                    destinationChain,
                    gasValue,
                    { value: gasValue },
                ),
            )
                .to.emit(service, 'RemoteStandardizedTokenAndManagerDeploymentInitialized')
                .withArgs(
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                    destinationChain,
                    gasValue,
                )
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should revert on remote standardized token deployment if paused', async () => {
            let tx = await service.setPaused(true);
            await tx.wait();

            await expectRevert(
                (gasOptions) =>
                    service.deployAndRegisterRemoteStandardizedToken(
                        salt,
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        distributor,
                        mintTo,
                        mintAmount,
                        operator,
                        destinationChain,
                        gasValue,
                        { ...gasOptions, value: gasValue },
                    ),
                service,
                'Paused',
            );

            tx = await service.setPaused(false);
            await tx.wait();
        });
    });

    describe('Receive Remote Standardized Token Deployment', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let sourceAddress;
        let txPaused;

        before(async () => {
            sourceAddress = service.address.toLowerCase();
        });

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should revert on receiving a remote standardized token depoloyment if not approved by the gateway', async () => {
            const tokenId = getRandomBytes32();
            const distributor = wallet.address;
            const operator = wallet.address;
            const mintTo = '0x';
            const mintAmount = 1234;
            const commandId = getRandomBytes32();
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );

            await expectRevert(
                (gasOptions) => service.execute(commandId, sourceChain, sourceAddress, payload, gasOptions),
                service,
                'NotApprovedByGateway',
            );
        });

        it('Should be able to receive a remote standardized token depoloyment with a lock/unlock token manager', async () => {
            const tokenId = getRandomBytes32();
            const distributor = wallet.address;
            const operator = wallet.address;
            const mintTo = '0x';
            const mintAmount = 1234;
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [distributor, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);
            const token = new Contract(tokenAddress, Token.abi, wallet);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, distributor, tokenName, tokenSymbol, tokenDecimals, mintAmount, distributor)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, mintAmount)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should be able to receive a remote standardized token depoloyment with a mint/burn token manager', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const distributor = tokenManagerAddress;
            const operator = wallet.address;
            const mintTo = '0x';
            const mintAmount = 0;
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, distributor, tokenName, tokenSymbol, tokenDecimals, mintAmount, distributor)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(operator, OPERATOR_ROLE)).to.be.true;
        });

        it('Should be able to receive a remote standardized token depoloyment with a mint/burn token manager with empty distributor and operator', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const distributor = '0x';
            const mintTo = '0x';
            const mintAmount = 1234;
            const operator = '0x';
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [service.address, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);
            const token = new Contract(tokenAddress, Token.abi, wallet);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenManagerAddress, tokenName, tokenSymbol, tokenDecimals, mintAmount, tokenManagerAddress)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenManagerAddress, mintAmount)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should be able to receive a remote standardized token depoloyment with a mint/burn token manager with non-empty mintTo bytes', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const distributor = '0x';
            const mintTo = arrayify(tokenManagerAddress);
            const mintAmount = 1234;
            const operator = '0x';
            const tokenAddress = await service.getStandardizedTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [service.address, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes', 'uint256', 'bytes'],
                [
                    SELECTOR_DEPLOY_AND_REGISTER_STANDARDIZED_TOKEN,
                    tokenId,
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    distributor,
                    mintTo,
                    mintAmount,
                    operator,
                ],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);
            const token = new Contract(tokenAddress, Token.abi, wallet);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(service, 'StandardizedTokenDeployed')
                .withArgs(tokenId, tokenManagerAddress, tokenName, tokenSymbol, tokenDecimals, mintAmount, tokenManagerAddress)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, tokenManagerAddress, mintAmount)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, MINT_BURN, params);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should revert on execute with token', async () => {
            const commandId = getRandomBytes32();
            const sourceAddress = 'Source Address';
            const payload = '0x';
            const amount = 123;

            await expectRevert(
                (gasOptions) => service.executeWithToken(commandId, sourceChain, sourceAddress, payload, tokenSymbol, amount, gasOptions),
                service,
                'ExecuteWithTokenNotSupported',
            );
        });
    });

    describe('Custom Token Manager Deployment', () => {
        let txPaused;

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should deploy a lock/unlock token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            const tx = service.deployCustomTokenManager(salt, LOCK_UNLOCK, params);
            await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, LOCK_UNLOCK, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

            const tokenAddress = await service.getTokenAddress(tokenId);
            expect(tokenAddress).to.eq(token.address);
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

            const tx = service.deployCustomTokenManager(salt, MINT_BURN, params);
            await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, MINT_BURN, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

            const tokenAddress = await service.getTokenAddress(tokenId);
            expect(tokenAddress).to.eq(token.address);
        });

        it('Should deploy a mint/burn_from token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            const tx = service.deployCustomTokenManager(salt, MINT_BURN_FROM, params);
            await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, MINT_BURN_FROM, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

            const tokenAddress = await service.getTokenAddress(tokenId);
            expect(tokenAddress).to.eq(token.address);
        });

        it('Should deploy a lock/unlock with fee on transfer token manager', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'FeeOnTransferTokenTest', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                tokenManagerAddress,
            ]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            const tx = service.deployCustomTokenManager(salt, LOCK_UNLOCK_FEE_ON_TRANSFER, params);
            await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, LOCK_UNLOCK_FEE_ON_TRANSFER, params);

            expect(tokenManagerAddress).to.not.equal(AddressZero);
            const tokenManager = new Contract(tokenManagerAddress, TokenManager.abi, wallet);

            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

            const tokenAddress = await service.getTokenAddress(tokenId);
            expect(tokenAddress).to.eq(token.address);
        });

        it('Should revert when deploying a custom token manager twice', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            const tx = service.deployCustomTokenManager(salt, LOCK_UNLOCK, params);
            await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, LOCK_UNLOCK, params);

            await expectRevert(
                (gasOptions) => service.deployCustomTokenManager(salt, LOCK_UNLOCK, params, gasOptions),
                service,
                'TokenManagerDeploymentFailed',
            );
        });

        it('Should revert when deploying a custom token manager if paused', async () => {
            let tx2 = await service.setPaused(true);
            await tx2.wait();

            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.getTokenManagerAddress(tokenId);
            const token = await deployContract(wallet, 'InterchainTokenTest', [tokenName, tokenSymbol, tokenDecimals, tokenManagerAddress]);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            await expectRevert((gasOptions) => service.deployCustomTokenManager(salt, LOCK_UNLOCK, params, gasOptions), service, 'Paused');

            tx2 = await service.setPaused(false);
            await tx2.wait();
        });
    });

    describe('Initialize remote custom token manager deployment', () => {
        let txPaused;

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should initialize a remote custom token manager deployment', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const gasValue = 1e6;
            const params = '0x1234';
            const type = LOCK_UNLOCK;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, type, params],
            );

            await expect(service.deployRemoteCustomTokenManager(salt, destinationChain, type, params, gasValue, { value: gasValue }))
                .to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, destinationChain, gasValue, type, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should revert on remote custom token manager deployment if paused', async () => {
            let tx = await service.setPaused(true);
            await tx.wait();

            const salt = getRandomBytes32();
            const gasValue = 1e6;
            const params = '0x1234';
            const type = LOCK_UNLOCK;

            await expectRevert(
                (gasOptions) =>
                    service.deployRemoteCustomTokenManager(salt, destinationChain, type, params, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Paused',
            );
            tx = await service.setPaused(false);
            await tx.wait();
        });
    });

    describe('Initialize remote standardized token and manager deployment', () => {
        let txPaused;

        beforeEach(async () => {
            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should initialize a remote custom token manager deployment', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.getCustomTokenId(wallet.address, salt);
            const gasValue = 1e6;
            const params = '0x1234';
            const type = LOCK_UNLOCK;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, type, params],
            );

            await expect(service.deployRemoteCustomTokenManager(salt, destinationChain, type, params, gasValue, { value: gasValue }))
                .to.emit(service, 'RemoteTokenManagerDeploymentInitialized')
                .withArgs(tokenId, destinationChain, gasValue, type, params)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), keccak256(payload), payload);
        });

        it('Should revert on remote custom token manager deployment if paused', async () => {
            let tx = await service.setPaused(true);
            await tx.wait();

            const salt = getRandomBytes32();
            const gasValue = 1e6;
            const params = '0x1234';
            const type = LOCK_UNLOCK;

            await expectRevert(
                (gasOptions) =>
                    service.deployRemoteCustomTokenManager(salt, destinationChain, type, params, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Paused',
            );
            tx = await service.setPaused(false);
            await tx.wait();
        });
    });

    describe('Receive Remote Token Manager Deployment', () => {
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
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should be able to receive a remote mint/burn token manager depoloyment', async () => {
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
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });
    });

    describe('Send Token', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        const gasValue = 90;

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256'],
                    [SELECTOR_SEND_TOKEN, tokenId, destAddress, sendAmount],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(tokenManager.interchainTransfer(destinationChain, destAddress, amount, '0x', { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'TokenSent')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount);
            });
        }

        it(`Should revert on initiate interchain token transfer when service is paused`, async () => {
            const [, tokenManager] = await deployFunctions.lockUnlock(`Test Token lockUnlock`, 'TT', 12, amount);

            let txPaused = await service.setPaused(true);
            await txPaused.wait();

            await expectRevert(
                (gasOptions) =>
                    tokenManager.interchainTransfer(destinationChain, destAddress, amount, '0x', { ...gasOptions, value: gasValue }),
                service,
                'Paused',
            );

            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it(`Should revert on transmit send token when not called by token manager`, async () => {
            const [, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token lockUnlock`, 'TT', 12, amount);

            await expectRevert(
                (gasOptions) =>
                    service.transmitSendToken(tokenId, tokenManager.address, destinationChain, destAddress, amount, '0x', {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'NotTokenManager',
            );
        });
    });

    describe('Execute checks', () => {
        const sourceChain = 'source chain';
        let sourceAddress;
        const amount = 1234;
        let destAddress;

        before(async () => {
            sourceAddress = service.address.toLowerCase();
            destAddress = wallet.address;
        });

        it('Should revert on execute if remote address validation fails', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount);
            (await await token.transfer(tokenManager.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, wallet.address, service.address, payload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, sourceChain, wallet.address, payload, gasOptions),
                service,
                'NotRemoteService',
            );
        });

        it('Should revert on execute if the service is paused', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount);
            (await await token.transfer(tokenManager.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            let txPaused = await service.setPaused(true);
            await txPaused.wait();

            await expectRevert(
                (gasOptions) => service.execute(commandId, sourceChain, sourceAddress, payload, gasOptions),
                service,
                'Paused',
            );

            txPaused = await service.setPaused(false);
            await txPaused.wait();
        });

        it('Should revert on execute with invalid selector', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount);
            (await await token.transfer(tokenManager.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [INVALID_SELECTOR, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, sourceChain, sourceAddress, payload, gasOptions),
                service,
                'SelectorUnknown',
            );
        });
    });

    describe('Receive Remote Tokens', () => {
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

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(`Test Token Mint Burn`, 'TT', 12, 0);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(`Test Token Lock Unlock`, 'TT', 12, amount + 10);
            (await await token.transfer(tokenManager.address, amount + 10)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'TokenReceived')
                .withArgs(tokenId, sourceChain, destAddress, amount - 10);
        });
    });

    describe('Send Token With Data', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        const gasValue = 90;
        let sourceAddress;
        const data = '0x1234';

        before(() => {
            sourceAddress = wallet.address;
        });

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                    [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, sendAmount, sourceAddress, data],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(tokenManager.callContractWithInterchainToken(destinationChain, destAddress, amount, data, { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'TokenSentWithData')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount, sourceAddress, data);
            });
        }

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer via the interchainTransfer function on the service [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const metadata = '0x00000000';
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                    [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, sendAmount, sourceAddress, '0x'],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .to.emit(service, 'TokenSentWithData')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount, sourceAddress, '0x');
            });
        }

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer via the sendTokenWithData function on the service [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                    [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, sendAmount, sourceAddress, data],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(service.sendTokenWithData(tokenId, destinationChain, destAddress, amount, data))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .to.emit(service, 'TokenSentWithData')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount, sourceAddress, data);
            });
        }

        it(`Should revert on interchainTransfer function with invalid metadata version`, async () => {
            const [, , tokenId] = await deployFunctions.lockUnlock(`Test Token lockUnlock`, 'TT', 12, amount);

            const metadata = '0x00000001';

            await expectRevert(
                (gasOptions) => service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, gasOptions),
                service,
                'InvalidMetadataVersion',
            );
        });
    });

    describe('Receive Remote Tokens with Data', () => {
        let sourceAddress;
        const sourceAddressForService = '0x1234';
        const amount = 1234;
        let destAddress;
        let executable;

        before(async () => {
            sourceAddress = service.address.toLowerCase();
            executable = await deployContract(wallet, 'InterchainExecutableTest', [service.address]);
            destAddress = executable.address;
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount);
            (await await token.transfer(tokenManager.address, amount)).wait();
            const msg = `lock/unlock`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount)
                .and.to.emit(service, 'TokenReceivedWithData')
                .withArgs(tokenId, sourceChain, destAddress, amount, sourceAddressForService, data)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(`Test Token Mint Burn`, 'TT', 12, amount);

            const msg = `mint/burn`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount)
                .and.to.emit(service, 'TokenReceivedWithData')
                .withArgs(tokenId, sourceChain, destAddress, amount, sourceAddressForService, data)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(`Test Token Lock Unlock`, 'TT', 12, amount + 10);
            (await await token.transfer(tokenManager.address, amount + 10)).wait();
            const msg = `lock/unlock`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount - 10)
                .and.to.emit(service, 'TokenReceivedWithData')
                .withArgs(tokenId, sourceChain, destAddress, amount - 10, sourceAddressForService, data)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount - 10);

            expect(await executable.lastMessage()).to.equal(msg);
        });
    });

    describe('Send Interchain Token', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        const gasValue = 90;
        const metadata = '0x';

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount, true);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256'],
                    [SELECTOR_SEND_TOKEN, tokenId, destAddress, sendAmount],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(token.interchainTransfer(destinationChain, destAddress, amount, metadata, { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'TokenSent')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount);
            });

            it(`Should be able to initiate an interchain token transfer using interchainTransferFrom [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount, true);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256'],
                    [SELECTOR_SEND_TOKEN, tokenId, destAddress, sendAmount],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                const sender = wallet;
                const spender = otherWallet;
                await token.approve(spender.address, amount).then((tx) => tx.wait());

                await expect(
                    token
                        .connect(spender)
                        .interchainTransferFrom(sender.address, destinationChain, destAddress, amount, metadata, { value: gasValue }),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, spender.address)
                    .to.emit(service, 'TokenSent')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount);
            });
        }

        it(`Should be able to initiate an interchain token transfer using interchainTransferFrom with max possible allowance`, async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token LockUnlock`, 'TT', 12, amount, true);
            const sendAmount = amount;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, sendAmount],
            );
            const payloadHash = keccak256(payload);

            const transferToAddress = tokenManager.address;

            const sender = wallet;
            const spender = otherWallet;
            await token.approve(spender.address, MaxUint256).then((tx) => tx.wait());

            await expect(
                token
                    .connect(spender)
                    .interchainTransferFrom(sender.address, destinationChain, destAddress, amount, metadata, { value: gasValue }),
            )
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, transferToAddress, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, spender.address)
                .to.emit(service, 'TokenSent')
                .withArgs(tokenId, destinationChain, destAddress, sendAmount);
        });
    });

    describe('Send Interchain Token With Data', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        const gasValue = 90;
        let sourceAddress;
        const data = '0x1234';

        before(() => {
            sourceAddress = wallet.address;
        });

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, amount, false);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;

                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                    [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, sendAmount, sourceAddress, data],
                );
                const payloadHash = keccak256(payload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                const metadata = solidityPack(['uint32', 'bytes'], [0, data]);
                await expect(token.interchainTransfer(destinationChain, destAddress, amount, metadata, { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, destinationChain, service.address.toLowerCase(), payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'TokenSentWithData')
                    .withArgs(tokenId, destinationChain, destAddress, sendAmount, sourceAddress, data);
            });
        }
    });

    describe('Express Execute', () => {
        const commandId = getRandomBytes32();
        const sourceAddress = '0x1234';
        const amount = 1234;
        const destinationAddress = new Wallet(getRandomBytes32()).address;
        const tokenName = 'name';
        const tokenSymbol = 'symbol';
        const tokenDecimals = 16;
        const message = 'message';
        let data;
        let tokenId;
        let executable;
        let token;

        before(async () => {
            [token, , tokenId] = await deployFunctions.lockUnlock(tokenName, tokenSymbol, tokenDecimals, amount * 2, true);
            await (await token.approve(service.address, amount * 2)).wait();
            data = defaultAbiCoder.encode(['address', 'string'], [destinationAddress, message]);
            executable = await deployContract(wallet, 'InterchainExecutableTest', [service.address]);
        });

        it('Should express execute', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destinationAddress, amount],
            );
            await expect(service.expressReceiveToken(payload, commandId, sourceChain))
                .to.emit(service, 'ExpressReceive')
                .withArgs(payload, commandId, wallet.address)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, destinationAddress, amount);
        });

        it('Should express execute with token', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', ' bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, executable.address, amount, sourceAddress, data],
            );
            await expect(service.expressReceiveToken(payload, commandId, sourceChain))
                .to.emit(service, 'ExpressReceive')
                .withArgs(payload, commandId, wallet.address)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, executable.address, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(executable.address, destinationAddress, amount)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(sourceChain, sourceAddress, destinationAddress, message, tokenId, amount);
        });
    });

    describe('Express Receive Remote Tokens', () => {
        let sourceAddress;
        const amount = 1234;
        const destAddress = new Wallet(getRandomBytes32()).address;

        before(async () => {
            sourceAddress = service.address.toLowerCase();
        });

        it('Should revert if command is already executed by gateway', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, 2 * amount);
            await (await token.transfer(tokenManager.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );

            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);
            await gateway.setCommandExecuted(commandId, true).then((tx) => tx.wait());

            await expectRevert(
                (gasOptions) => service.expressReceiveToken(payload, commandId, sourceChain, gasOptions),
                service,
                'AlreadyExecuted',
            );
        });

        it('Should revert with invalid selector', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, 2 * amount);
            await (await token.transfer(tokenManager.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_DEPLOY_TOKEN_MANAGER, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expectRevert(
                (gasOptions) => service.expressReceiveToken(payload, commandId, sourceChain, gasOptions),
                service,
                'InvalidExpressSelector',
            );
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, 2 * amount);
            await (await token.transfer(tokenManager.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await (await service.expressReceiveToken(payload, commandId, sourceChain)).wait();

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(payload, commandId, wallet.address);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(`Test Token Mint Burn`, 'TT', 12, amount);

            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await (await service.expressReceiveToken(payload, commandId, sourceChain)).wait();

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(payload, commandId, wallet.address);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(`Test Token Lock Unlock`, 'TT', 12, 2 * amount + 10);
            await (await token.transfer(tokenManager.address, amount + 10)).wait();
            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [SELECTOR_SEND_TOKEN, tokenId, destAddress, amount],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await (await service.expressReceiveToken(payload, commandId, sourceChain)).wait();

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(payload, commandId, wallet.address);
        });
    });

    describe('Express Receive Remote Tokens with Data', () => {
        let sourceAddress;
        const sourceAddressForService = '0x1234';
        const amount = 1234;
        let destAddress;
        let executable;

        before(async () => {
            sourceAddress = service.address.toLowerCase();
            executable = await deployContract(wallet, 'InterchainExecutableTest', [service.address]);
            destAddress = executable.address;
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(`Test Token Lock Unlock`, 'TT', 12, amount * 2);
            await (await token.transfer(tokenManager.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const msg = `lock/unlock`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await (await service.expressReceiveToken(payload, commandId, sourceChain)).wait();

            const tx = service.execute(commandId, sourceChain, sourceAddress, payload);
            await expect(tx)
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(payload, commandId, wallet.address);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(`Test Token Mint Burn`, 'TT', 12, amount);
            await (await token.approve(service.address, amount)).wait();

            const msg = `mint/burn`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );

            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await (await service.expressReceiveToken(payload, commandId, sourceChain)).wait();

            await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(payload, commandId, wallet.address);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(`Test Token Lock Unlock`, 'TT', 12, amount * 2 + 10);
            await (await token.transfer(tokenManager.address, amount + 10)).wait();
            await (await token.approve(service.address, amount)).wait();

            const msg = `lock/unlock`;
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256', 'bytes', 'bytes'],
                [SELECTOR_SEND_TOKEN_WITH_DATA, tokenId, destAddress, amount, sourceAddressForService, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.expressReceiveToken(payload, commandId, sourceChain)).to.be.reverted;
        });
    });

    describe('Flow Limits', () => {
        const destinationAddress = '0x1234';
        let tokenManager, tokenId;
        const sendAmount = 1234;
        const flowLimit = (sendAmount * 3) / 2;
        const mintAmount = flowLimit * 3;

        beforeEach(async () => {
            [, tokenManager, tokenId] = await deployFunctions.mintBurn(`Test Token Lock Unlock`, 'TT', 12, mintAmount);
            await (await tokenManager.setFlowLimit(flowLimit)).wait();
        });

        it('Should be able to send token only if it does not trigger the mint limit', async () => {
            await (await tokenManager.interchainTransfer(destinationChain, destinationAddress, sendAmount, '0x')).wait();
            await expectRevert(
                (gasOptions) => tokenManager.interchainTransfer(destinationChain, destinationAddress, sendAmount, '0x', gasOptions),
                tokenManager,
                'FlowLimitExceeded',
            );
        });

        it('Should be able to receive token only if it does not trigger the mint limit', async () => {
            const tokenFlowLimit = await service.getFlowLimit(tokenId);
            expect(tokenFlowLimit).to.eq(flowLimit);

            let flowIn = await service.getFlowInAmount(tokenId);
            let flowOut = await service.getFlowOutAmount(tokenId);

            expect(flowIn).to.eq(0);
            expect(flowOut).to.eq(0);

            async function receiveToken(sendAmount) {
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'uint256'],
                    [SELECTOR_SEND_TOKEN, tokenId, wallet.address, sendAmount],
                );
                const commandId = await approveContractCall(gateway, destinationChain, service.address, service.address, payload);

                return service.execute(commandId, destinationChain, service.address, payload);
            }

            await (await receiveToken(sendAmount)).wait();

            flowIn = await service.getFlowInAmount(tokenId);
            flowOut = await service.getFlowOutAmount(tokenId);

            expect(flowIn).to.eq(sendAmount);
            expect(flowOut).to.eq(0);

            await expectRevert((gasOptions) => receiveToken(sendAmount, gasOptions), tokenManager, 'FlowLimitExceeded');
        });

        it('Should be able to set flow limits for each token manager', async () => {
            const tokenIds = [];
            const tokenManagers = [];

            for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
                const [, tokenManager, tokenId] = await deployFunctions[type](`Test Token ${type}`, 'TT', 12, mintAmount);
                tokenIds.push(tokenId);
                tokenManagers.push(tokenManager);

                await tokenManager.addFlowLimiter(service.address).then((tx) => tx.wait());
            }

            const flowLimits = new Array(tokenManagers.length).fill(flowLimit);

            await expectRevert(
                (gasOptions) => service.connect(otherWallet).setFlowLimits(tokenIds, flowLimits, gasOptions),
                service,
                'MissingRole',
            );

            await expect(service.setFlowLimits(tokenIds, flowLimits))
                .to.emit(tokenManagers[0], 'FlowLimitSet')
                .withArgs(flowLimit)
                .to.emit(tokenManagers[1], 'FlowLimitSet')
                .withArgs(flowLimit)
                .to.emit(tokenManagers[2], 'FlowLimitSet')
                .withArgs(flowLimit);

            flowLimits.pop();

            await expectRevert((gasOptions) => service.setFlowLimits(tokenIds, flowLimits, gasOptions), service, 'LengthMismatch');
        });
    });

    describe('Flow Limiters', () => {
        let tokenManager;
        const sendAmount = 1234;
        const flowLimit = (sendAmount * 3) / 2;
        const mintAmount = flowLimit * 3;

        beforeEach(async () => {
            [, tokenManager] = await deployFunctions.mintBurn(`Test Token Lock Unlock`, 'TT', 12, mintAmount);
        });

        it('Should have only the owner be a flow limiter', async() => {
            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
        });

        it('Should be able to add a flow limiter', async() => {
            await expect(tokenManager.addFlowLimiter(otherWallet.address))
                .to.emit(tokenManager, 'RolesAdded')
                .withArgs(otherWallet.address, [FLOW_LIMITER_ROLE]);
            

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
        });

        it('Should be able to remove a flow limiter', async() => {
            await expect(tokenManager.removeFlowLimiter(wallet.address))
                .to.emit(tokenManager, 'RolesRemoved')
                .withArgs(wallet.address, [FLOW_LIMITER_ROLE]);
            

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
        });

        it('Should revert if trying to add a flow limiter as not the operator', async() => {
            await expectRevert(
                (gasOptions) => tokenManager.connect(otherWallet).addFlowLimiter(otherWallet.address, gasOptions),
                tokenManager, 
                'MissingRole');
        });

        it('Should revert if trying to add a flow limiter as not the operator', async() => {
            await expectRevert(
                (gasOptions) => tokenManager.connect(otherWallet).removeFlowLimiter(wallet.address, gasOptions),
                tokenManager, 
                'MissingRole');
        });

        it('Should revert if trying to add an existing flow limiter', async() => {
            await expectRevert(
                (gasOptions) => tokenManager.addFlowLimiter(wallet.address, gasOptions),
                tokenManager, 
                'AlreadyFlowLimiter');
        });

        it('Should revert if trying to add a flow limiter as not the operator', async() => {
            await expectRevert(
                (gasOptions) => tokenManager.removeFlowLimiter(otherWallet.address, gasOptions),
                tokenManager, 
                'NotFlowLimiter');
        });


    })
});
