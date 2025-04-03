'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const {
    Wallet,
    constants: { MaxUint256, AddressZero, HashZero },
    utils: { defaultAbiCoder, solidityPack, keccak256, toUtf8Bytes, hexlify, id },
    getContractAt,
} = ethers;
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { approveContractCall } = require('../scripts/utils');
const { getRandomBytes32, getRandomInt, expectRevert, gasReporter, getEVMVersion } = require('./utils');
const { deployAll, deployContract, deployInterchainTokenService } = require('../scripts/deploy');
const {
    MESSAGE_TYPE_INTERCHAIN_TRANSFER,
    MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN,
    MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER,
    MESSAGE_TYPE_RECEIVE_FROM_HUB,
    MESSAGE_TYPE_LINK_TOKEN,
    INVALID_MESSAGE_TYPE,
    NATIVE_INTERCHAIN_TOKEN,
    MINT_BURN_FROM,
    LOCK_UNLOCK,
    LOCK_UNLOCK_FEE_ON_TRANSFER,
    MINT_BURN,
    OPERATOR_ROLE,
    FLOW_LIMITER_ROLE,
    ITS_HUB_CHAIN,
    ITS_HUB_ADDRESS,
    MINTER_ROLE,
    MESSAGE_TYPE_REGISTER_TOKEN_METADATA,
    MESSAGE_TYPE_SEND_TO_HUB,
} = require('./constants');

const reportGas = gasReporter('Interchain Token Service');

describe('Interchain Token Service', () => {
    let wallet, otherWallet;
    let service, gateway, gasService, testToken;

    let create3Deployer;
    let tokenManagerDeployer;
    let interchainToken;
    let interchainTokenDeployer;
    let tokenManager;
    let tokenHandler;
    let gatewayCaller;

    const chainName = 'Test';
    const deploymentKey = 'InterchainTokenService';
    const factoryDeploymentKey = 'factoryKey';

    const deployFunctions = {};
    const destinationChain = 'destination chain';
    const sourceChain = 'source chain';
    const gasValue = 12;

    async function deployNewLockUnlock(service, tokenName, tokenSymbol, tokenDecimals, mintAmount = 0, skipApprove = false) {
        const salt = getRandomBytes32();
        const tokenId = await service.interchainTokenId(wallet.address, salt);
        const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
        const tokenManagerType = LOCK_UNLOCK;
        const sourceTokenAddress = '0x1234';
        const minter = wallet.address;

        const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
            tokenName,
            tokenSymbol,
            tokenDecimals,
            service.address,
            tokenId,
        ]);

        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
        const payload = defaultAbiCoder.encode(
            ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
            [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
        );
        const wrappedPayload = defaultAbiCoder.encode(
            ['uint256', 'string', 'bytes'],
            [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
        );
        const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);
        const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

        await expect(
            reportGas(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload), 'Receive GMP DEPLOY_TOKEN_MANAGER'),
        )
            .to.emit(service, 'TokenManagerDeployed')
            .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);

        const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
        expect(await tokenManager.tokenAddress()).to.equal(token.address);
        expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

        if (mintAmount > 0) {
            await token.mint(wallet.address, mintAmount).then((tx) => tx.wait);
            if (!skipApprove) await token.approve(service.address, mintAmount).then((tx) => tx.wait);
        }

        return [token, tokenManager, tokenId, salt];
    }

    async function deployNewLockUnlockFee(
        service,
        tokenName,
        tokenSymbol,
        tokenDecimals,
        mintAmount = 0,
        skipApprove = false,
        type = 'normal',
    ) {
        const salt = getRandomBytes32();
        const tokenId = await service.interchainTokenId(wallet.address, salt);
        const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
        const tokenManagerType = LOCK_UNLOCK_FEE_ON_TRANSFER;
        const sourceTokenAddress = '0x1234';
        const minter = wallet.address;

        let token;

        if (type === 'free') {
            token = await deployContract(wallet, 'TestFeeOnTransferTokenNoFee', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);
        } else if (type === 'reentrant') {
            token = await deployContract(wallet, 'TestFeeOnTransferTokenInvalid', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);
        } else {
            token = await deployContract(wallet, 'TestFeeOnTransferToken', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);
        }

        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
        const payload = defaultAbiCoder.encode(
            ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
            [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
        );
        const wrappedPayload = defaultAbiCoder.encode(
            ['uint256', 'string', 'bytes'],
            [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
        );
        const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);
        const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

        await expect(
            reportGas(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload), 'Receive GMP DEPLOY_TOKEN_MANAGER'),
        )
            .to.emit(service, 'TokenManagerDeployed')
            .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);

        const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
        expect(await tokenManager.tokenAddress()).to.equal(token.address);
        expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;

        if (mintAmount > 0) {
            await token.mint(wallet.address, mintAmount).then((tx) => tx.wait);

            if (!skipApprove) {
                await token.approve(service.address, mintAmount).then((tx) => tx.wait);
            }
        }

        return [token, tokenManager, tokenId];
    }

    const makeDeployNewMintBurn = (type) =>
        async function deployNewMintBurn(service, tokenName, tokenSymbol, tokenDecimals, mintAmount = 0) {
            const salt = getRandomBytes32();
            const tokenId = await service.interchainTokenId(wallet.address, salt);
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManagerType = type;
            const sourceTokenAddress = '0x1234';
            const minter = wallet.address;

            const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);

            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

            if (mintAmount > 0) {
                await token.mint(wallet.address, mintAmount).then((tx) => tx.wait);
            }

            await token.transferMintership(tokenManager.address).then((tx) => tx.wait);

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(
                reportGas(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload), 'Receive GMP DEPLOY_TOKEN_MANAGER'),
            )
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);

            expect(await tokenManager.tokenAddress()).to.equal(token.address);

            return [token, tokenManager, tokenId];
        };

    async function deployNewInterchainToken(
        service,
        tokenName,
        tokenSymbol,
        tokenDecimals,
        minter = null,
        mintAmount = 0,
        skipApprove = false,
    ) {
        const salt = getRandomBytes32();
        const tokenId = await service.interchainTokenId(wallet.address, salt);

        const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
        const operator = '0x';
        const tokenAddress = await service.interchainTokenAddress(tokenId);
        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, tokenAddress]);
        const payload = defaultAbiCoder.encode(
            ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
            [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, wallet.address, operator],
        );
        const wrappedPayload = defaultAbiCoder.encode(
            ['uint256', 'string', 'bytes'],
            [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
        );
        const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

        await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
            .to.emit(service, 'InterchainTokenDeployed')
            .withArgs(tokenId, tokenAddress, wallet.address, tokenName, tokenSymbol, tokenDecimals)
            .and.to.emit(service, 'TokenManagerDeployed')
            .withArgs(tokenId, tokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, params);
        const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
        expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
        expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;

        const token = await getContractAt('IInterchainToken', tokenAddress, wallet);

        if (mintAmount > 0) {
            await token.mint(wallet.address, mintAmount).then((tx) => tx.wait);
            if (!skipApprove) await token.approve(service.address, mintAmount).then((tx) => tx.wait);
        }

        if (minter) {
            await token.transferMintership(minter).then((tx) => tx.wait);
        }

        return [token, tokenManager, tokenId, salt];
    }

    deployFunctions.lockUnlock = deployNewLockUnlock;
    deployFunctions.lockUnlockFee = deployNewLockUnlockFee;
    deployFunctions.mintBurn = makeDeployNewMintBurn(MINT_BURN);
    deployFunctions.mintBurnFrom = makeDeployNewMintBurn(MINT_BURN_FROM);
    deployFunctions.interchainToken = deployNewInterchainToken;

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        otherWallet = wallets[1];

        ({
            service,
            gateway,
            gasService,
            create3Deployer,
            tokenManagerDeployer,
            interchainToken,
            interchainTokenDeployer,
            tokenManager,
            tokenHandler,
            gatewayCaller,
        } = await deployAll(wallet, 'Test', ITS_HUB_ADDRESS, [sourceChain, destinationChain]));

        testToken = await deployContract(wallet, 'TestInterchainTokenStandard', [
            'Test Token',
            'TST',
            18,
            service.address,
            getRandomBytes32(),
        ]);
    });

    describe('Interchain Token Service Deployment', () => {
        let interchainTokenFactoryAddress;
        let serviceTest;

        before(async () => {
            interchainTokenFactoryAddress = await getCreate3Address(create3Deployer.address, wallet, factoryDeploymentKey);
            serviceTest = await deployContract(wallet, 'TestInterchainTokenService', [
                tokenManagerDeployer.address,
                interchainTokenDeployer.address,
                gateway.address,
                gasService.address,
                interchainTokenFactoryAddress,
                chainName,
                ITS_HUB_ADDRESS,
                tokenManager.address,
                tokenHandler.address,
                gatewayCaller.address,
            ]);
        });

        it('Should clear previously set addresses', async () => {
            const operator = wallet.address;
            const trustedChainName = 'ChainA';
            const trustedAddress = wallet.address;

            await expect(serviceTest.setTrustedAddress(trustedChainName, trustedAddress))
                .to.emit(serviceTest, 'TrustedAddressSet')
                .withArgs(trustedChainName, trustedAddress);

            const params = defaultAbiCoder.encode(['address', 'string', 'string[]'], [operator, chainName, [trustedChainName]]);
            await expect(serviceTest.setupTest(params)).to.emit(serviceTest, 'TrustedAddressRemoved').withArgs(trustedChainName);
        });

        it('Should test setup revert cases', async () => {
            const operator = wallet.address;
            const trustedChainNames = ['ChainA', 'ChainB'];
            const trustedAddresses = [wallet.address, wallet.address];

            let params = defaultAbiCoder.encode(
                ['address', 'string', 'string[]', 'string[]'],
                [AddressZero, chainName, trustedChainNames, trustedAddresses],
            );

            await expectRevert((gasOptions) => serviceTest.setupTest(params, gasOptions), serviceTest, 'ZeroAddress');

            params = defaultAbiCoder.encode(
                ['address', 'string', 'string[]', 'string[]'],
                [operator, '', trustedChainNames, trustedAddresses],
            );

            await expectRevert((gasOptions) => serviceTest.setupTest(params, gasOptions), serviceTest, 'InvalidChainName');

            params = defaultAbiCoder.encode(
                ['address', 'string', 'string[]', 'string[]'],
                [operator, 'Invalid', trustedChainNames, trustedAddresses],
            );

            await expectRevert((gasOptions) => serviceTest.setupTest(params, gasOptions), serviceTest, 'InvalidChainName');
        });

        it('Should revert on invalid interchain token factory', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        interchainTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        AddressZero,
                        tokenManager.address,
                        tokenHandler.address,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
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
                        interchainTokenDeployer.address,
                        gateway.address,
                        AddressZero,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        tokenHandler.address,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid chain name', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        interchainTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        tokenHandler.address,
                        gatewayCaller.address,
                        '',
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'InvalidChainName',
            );
        });

        it('Should revert on invalid token manager deployer', async () => {
            await expectRevert((gasOptions) =>
                deployInterchainTokenService(
                    wallet,
                    create3Deployer.address,
                    AddressZero,
                    interchainTokenDeployer.address,
                    gateway.address,
                    gasService.address,
                    interchainTokenFactoryAddress,
                    tokenManager.address,
                    tokenHandler.address,
                    gatewayCaller.address,
                    chainName,
                    ITS_HUB_ADDRESS,
                    [],
                    deploymentKey,
                    gasOptions,
                ),
            );
        });

        it('Should revert on invalid interchain token deployer', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        AddressZero,
                        gateway.address,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        tokenHandler.address,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
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
                        interchainTokenDeployer.address,
                        AddressZero,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        tokenHandler.address,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid token manager implementation', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        interchainTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        AddressZero,
                        tokenHandler.address,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid token handler', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        interchainTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        AddressZero,
                        gatewayCaller.address,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid gateway caller', async () => {
            await expectRevert(
                (gasOptions) =>
                    deployInterchainTokenService(
                        wallet,
                        create3Deployer.address,
                        tokenManagerDeployer.address,
                        interchainTokenDeployer.address,
                        gateway.address,
                        gasService.address,
                        interchainTokenFactoryAddress,
                        tokenManager.address,
                        tokenHandler.address,
                        AddressZero,
                        chainName,
                        ITS_HUB_ADDRESS,
                        [],
                        deploymentKey,
                        gasOptions,
                    ),
                service,
                'ZeroAddress',
            );
        });

        it('Should revert on invalid its hub address', async () => {
            await expectRevert((gasOptions) =>
                deployInterchainTokenService(
                    wallet,
                    create3Deployer.address,
                    tokenManagerDeployer.address,
                    interchainTokenDeployer.address,
                    gateway.address,
                    gasService.address,
                    interchainTokenFactoryAddress,
                    tokenManager.address,
                    tokenHandler.address,
                    gatewayCaller.address,
                    chainName,
                    '',
                    [],
                    deploymentKey,
                ),
            );
        });

        it('Should return the correct contract id', async () => {
            const expectedContractid = keccak256(toUtf8Bytes('interchain-token-service'));
            const contractId = await service.contractId();
            expect(contractId).to.eq(expectedContractid);
        });

        it('Should return the token manager implementation', async () => {
            const tokenManagerImplementation = await service.tokenManagerImplementation(getRandomInt(1000));
            expect(tokenManagerImplementation).to.eq(tokenManager.address);
        });

        it('Should revert on TokenManagerProxy deployment with invalid constructor parameters', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.interchainTokenId(wallet.address, salt);
            const validParams = defaultAbiCoder.encode(['bytes', 'address'], ['0x', interchainToken.address]);
            const tokenManagerProxy = await deployContract(wallet, 'TestTokenManagerProxy', [
                service.address,
                MINT_BURN,
                tokenId,
                validParams,
            ]);
            const invalidParams = '0x1234';

            const contractId = await tokenManagerProxy.getContractId();
            const expectedContractid = keccak256(toUtf8Bytes('token-manager'));
            expect(contractId).to.eq(expectedContractid);

            await expectRevert(
                (gasOptions) => deployContract(wallet, 'TokenManagerProxy', [AddressZero, LOCK_UNLOCK, tokenId, validParams, gasOptions]),
                tokenManagerProxy,
                'ZeroAddress',
                [],
            );

            const invalidService = await deployContract(wallet, 'InvalidService');

            await expectRevert(
                (gasOptions) =>
                    deployContract(wallet, 'TokenManagerProxy', [invalidService.address, LOCK_UNLOCK, tokenId, validParams, gasOptions]),
                tokenManagerProxy,
                'InvalidImplementation',
                [],
            );

            await expectRevert(
                (gasOptions) =>
                    deployContract(wallet, 'TokenManagerProxy', [service.address, LOCK_UNLOCK, tokenId, invalidParams, gasOptions]),
                tokenManagerProxy,
                'SetupFailed',
                [],
            );

            await deployContract(wallet, 'TokenManagerProxy', [service.address, LOCK_UNLOCK, tokenId, validParams]);
        });

        it('Should revert when deploying a remote interchain token to self as not the factory', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();

            await expectRevert(
                (gasOptions) =>
                    serviceTest.deployInterchainToken(salt, '', tokenName, tokenSymbol, tokenDecimals, wallet.address, 0, gasOptions),
                serviceTest,
                'NotInterchainTokenFactory',
            );
        });

        it('Should revert when deploying a remote token manager to self', async () => {
            const salt = getRandomBytes32();

            await expectRevert(
                (gasOptions) => serviceTest.linkToken(salt, chainName, testToken.address, LOCK_UNLOCK, '0x', 0, gasOptions),
                serviceTest,
                'CannotDeployRemotelyToSelf',
            );
        });
    });

    describe('Owner functions', () => {
        it('Should revert on set pause status when not called by the owner', async () => {
            await expectRevert((gasOptions) => service.connect(otherWallet).setPauseStatus(true, gasOptions), service, 'NotOwner');
        });
    });

    describe('Operator functions', () => {
        const chain = 'Test';

        it('Should revert on set trusted chain when not called by the owner', async () => {
            await expectRevert((gasOptions) => service.connect(otherWallet).setTrustedChain(chain, gasOptions), service, 'MissingRole', [
                otherWallet.address,
                OPERATOR_ROLE,
            ]);
        });

        it('Should set trusted chain', async () => {
            await expect(service.setTrustedChain(chain)).to.emit(service, 'TrustedChainSet').withArgs(chain);
        });

        it('Should revert on remove trusted address when not called by the owner', async () => {
            await expectRevert((gasOptions) => service.connect(otherWallet).removeTrustedChain(chain, gasOptions), service, 'MissingRole', [
                otherWallet.address,
                OPERATOR_ROLE,
            ]);
        });

        it('Should remove trusted address', async () => {
            await expect(service.removeTrustedChain(chain)).to.emit(service, 'TrustedChainRemoved').withArgs(chain);
        });
    });

    describe('Token Handler', () => {
        const amount = 1234;

        it('Should revert on give token with non existing token id', async () => {
            await expectRevert((gasOptions) => tokenHandler.giveToken(getRandomBytes32(), otherWallet.address, amount, gasOptions));
        });

        it('Should revert on take token with non existing token id', async () => {
            await expectRevert((gasOptions) => tokenHandler.takeToken(getRandomBytes32(), false, otherWallet.address, amount, gasOptions));
        });

        it('Should revert on transfer token from non existing token id', async () => {
            await expectRevert((gasOptions) =>
                tokenHandler.transferTokenFrom(getRandomBytes32(), otherWallet.address, otherWallet.address, amount, gasOptions),
            );
        });
    });

    describe('Deploy and Register Interchain Token', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        const salt = getRandomBytes32();

        it('Should revert when registering an interchain token when service is paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) =>
                    service.deployInterchainToken(salt, '', tokenName, tokenSymbol, tokenDecimals, wallet.address, 0, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });
    });

    describe('Deploy and Register remote Interchain Token', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        const minter = '0x1234';
        let salt, tokenId;

        before(async () => {
            salt = getRandomBytes32();
            tokenId = await service.interchainTokenId(wallet.address, salt);

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const minter = '0x';
            const operator = '0x';
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter, operator],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, destinationChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, AddressZero, tokenName, tokenSymbol, tokenDecimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, params);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should revert on remote interchain token deployment if paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) =>
                    service.deployInterchainToken(salt, destinationChain, tokenName, tokenSymbol, tokenDecimals, minter, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });
    });

    describe('Receive Remote Interchain Token Deployment', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;

        it('Should revert on receiving a remote interchain token deployment if not approved by the gateway', async () => {
            const tokenId = getRandomBytes32();
            const minter = wallet.address;
            const commandId = getRandomBytes32();
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, destinationChain, payload],
            );

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'NotApprovedByGateway',
            );
        });

        it('Should be able to receive a remote interchain token deployment with a mint/burn token manager with empty minter and operator', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const minter = '0x';
            const operator = '0x';
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, tokenAddress]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter, operator],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, destinationChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, AddressZero, tokenName, tokenSymbol, tokenDecimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, params);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(tokenAddress);
            expect(await tokenManager.hasRole(service.address, OPERATOR_ROLE)).to.be.true;
        });
    });

    describe('Register Token Metadata', () => {
        const decimals = 18;
        let token;

        before(async () => {
            token = await deployContract(wallet, 'TestInterchainTokenStandard', ['Test', 'TEST', decimals, service.address, HashZero]);
        });

        it('Should revert on registering token metadata with empty token address', async () => {
            await expectRevert((gasOptions) => service.registerTokenMetadata(AddressZero, 0, gasOptions), service, 'EmptyTokenAddress');
        });

        it('Should successfully register token metadata', async () => {
            const gasValue = 0;
            const expectedPayload = defaultAbiCoder.encode(
                ['uint256', 'bytes', 'uint8'],
                [MESSAGE_TYPE_REGISTER_TOKEN_METADATA, token.address, decimals],
            );

            await expect(reportGas(service.registerTokenMetadata(token.address, gasValue), 'registerTokenMetadata'))
                .to.emit(service, 'TokenMetadataRegistered')
                .withArgs(token.address, decimals)
                .to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(expectedPayload), expectedPayload);
        });
    });

    describe('Custom Token Manager Deployment', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;
        let token, salt, tokenId;

        before(async () => {
            salt = getRandomBytes32();
            tokenId = await service.interchainTokenId(wallet.address, salt);
            token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);
        });

        it('Should revert when calling registerCustomToken as not the factory', async () => {
            await expectRevert(
                (gasOptions) => service.registerCustomToken(salt, AddressZero, LOCK_UNLOCK, '0x', gasOptions),
                service,
                'NotInterchainTokenFactory',
                [wallet.address],
            );
        });

        it('Should revert on deploying an invalid token manager', async () => {
            await expectRevert((gasOptions) => service.linkToken(salt, '', token.address, 6, wallet.address, 0, gasOptions));
        });

        it('Should revert on deploying a local token manager with invalid params', async () => {
            await expectRevert(
                (gasOptions) => service.linkToken(salt, '', token.address, NATIVE_INTERCHAIN_TOKEN, '0x', 0, gasOptions),
                service,
                'CannotDeploy',
            );
        });

        it('Should revert on deploying a local token manager with interchain token manager type', async () => {
            await expectRevert(
                (gasOptions) => service.linkToken(salt, '', token.address, NATIVE_INTERCHAIN_TOKEN, wallet.address, 0, gasOptions),
                service,
                'CannotDeploy',
                [NATIVE_INTERCHAIN_TOKEN],
            );
        });

        it('Should revert on deploying a local token manager with invalid params', async () => {
            await expectRevert(
                (gasOptions) => service.linkToken(salt, '', token.address, LOCK_UNLOCK, '0x12', 0, gasOptions),
                service,
                'NotSupported',
            );
        });

        it('Should revert on linking a token with empty token address', async () => {
            await expectRevert(
                (gasOptions) => service.linkToken(salt, '', '0x', MINT_BURN, wallet.address, 0, gasOptions),
                service,
                'EmptyTokenAddress',
            );
        });

        it('Should revert on deploying a remote token manager with interchain token manager type', async () => {
            await expectRevert(
                (gasOptions) =>
                    service.linkToken(salt, destinationChain, token.address, NATIVE_INTERCHAIN_TOKEN, wallet.address, 0, gasOptions),
                service,
                'CannotDeploy',
                [NATIVE_INTERCHAIN_TOKEN],
            );
        });

        it('Should revert when deploying a custom token manager if paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) => service.linkToken(salt, '', token.address, LOCK_UNLOCK, wallet.address, 0, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });
    });

    describe('Initialize remote custom token manager deployment', () => {
        let salt, tokenId;
        before(async () => {
            [, , tokenId, salt] = await deployFunctions.lockUnlock(service, 'Name', 'symbol', 6);
        });
        it('Should initialize a remote custom token manager deployment', async () => {
            const tokenAddress = await service.registeredTokenAddress(tokenId);
            const remoteTokenAddress = '0x1234';
            const minter = '0x5789';
            const type = LOCK_UNLOCK;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, type, tokenAddress, remoteTokenAddress, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
            );

            await expect(
                reportGas(
                    service.linkToken(salt, destinationChain, remoteTokenAddress, type, minter, gasValue, { value: gasValue }),
                    'Send deployTokenManager to remote chain',
                ),
            )
                .to.emit(service, 'InterchainTokenIdClaimed')
                .withArgs(tokenId, wallet.address, salt)
                .to.emit(service, 'LinkTokenStarted')
                .withArgs(
                    tokenId,
                    destinationChain,
                    tokenAddress.toLowerCase(),
                    remoteTokenAddress.toLowerCase(),
                    type,
                    minter.toLowerCase(),
                )
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wrappedPayload);
        });

        it('Should revert on a remote custom token manager deployment if the token manager does does not exist', async () => {
            const salt = getRandomBytes32();
            const tokenId = await service.interchainTokenId(wallet.address, salt);
            const tokenAddress = '0x1234';
            const minter = '0x5678';
            const type = LOCK_UNLOCK;

            await expect(
                service.linkToken(salt, destinationChain, tokenAddress, type, minter, gasValue, { value: gasValue }),
            ).to.be.revertedWithCustomError(service, 'TokenManagerDoesNotExist', [tokenId]);
        });

        it('Should revert on remote custom token manager deployment if paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            const salt = getRandomBytes32();
            const tokenAddress = '0x1234';
            const minter = '0x5678';
            const type = LOCK_UNLOCK;

            await expectRevert(
                (gasOptions) =>
                    service.linkToken(salt, destinationChain, tokenAddress, type, minter, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });
    });

    describe('Receive Remote Token Manager Deployment', () => {
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 13;

        it('Should be able to receive a remote lock/unlock token manager deployment', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManagerType = LOCK_UNLOCK;
            const sourceTokenAddress = '0x1234';
            const minter = wallet.address;

            const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(
                reportGas(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload), 'Receive GMP DEPLOY_TOKEN_MANAGER'),
            )
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);

            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(token.address);
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should be able to receive a remote mint/burn token manager deployment', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManagerType = MINT_BURN;
            const sourceTokenAddress = '0x1234';
            const minter = wallet.address;

            const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(token.address);
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should not be able to receive a remote interchain token manager deployment', async () => {
            const tokenId = getRandomBytes32();
            const tokenManagerType = NATIVE_INTERCHAIN_TOKEN;
            const sourceTokenAddress = '0x1234';
            const minter = wallet.address;

            const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, tokenManagerType, sourceTokenAddress, token.address, minter],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'CannotDeploy',
                [NATIVE_INTERCHAIN_TOKEN],
            );
        });
    });

    describe('Send Token', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        let token, tokenId;

        before(async () => {
            [token, , tokenId] = await deployFunctions.lockUnlock(service, 'Test Token lockUnlock', 'TT', 12, amount);
        });

        it('Should be able to initiate an interchain token transfer for lockUnlockFee with a normal ERC20 token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token lockUnlockFee',
                'TT',
                12,
                amount,
                false,
                'free',
            );

            const sendAmount = amount;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, sendAmount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
            );
            const payloadHash = keccak256(wrappedPayload);

            const transferToAddress = tokenManager.address;

            await expect(service.interchainTransfer(tokenId, destinationChain, destAddress, amount, '0x', gasValue, { value: gasValue }))
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, transferToAddress, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, wallet.address, destinationChain, destAddress, sendAmount, HashZero);
        });

        it('Should revert on initiating an interchain token transfer for lockUnlockFee with reentrant token', async () => {
            const [, , tokenId] = await deployFunctions.lockUnlockFee(service, 'Test Token lockUnlockFee', 'TT', 12, amount, 'reentrant');

            const revertData = keccak256(toUtf8Bytes('TokenTransferFailed()')).substring(0, 10);

            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, destinationChain, destAddress, amount, '0x', gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'TakeTokenFailed',
                [revertData],
            );
        });

        it('Should revert on initiate interchain token transfer with zero amount', async () => {
            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, destinationChain, destAddress, 0, '0x', gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'ZeroAmount',
            );
        });

        it('Should revert on initiate interchain token transfer with invalid destination address', async () => {
            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, destinationChain, '0x', amount, '0x', gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'EmptyDestinationAddress',
            );
        });

        it('Should revert on initiate an interchain token transfer to the ITS HUB', async () => {
            const [, , tokenId] = await deployFunctions.lockUnlockFee(service, 'Test Token lockUnlockFee', 'TT', 12, amount, false, 'free');

            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, ITS_HUB_CHAIN, destAddress, amount, '0x', gasValue, {
                        value: gasValue,
                        ...gasOptions,
                    }),
                service,
                'UntrustedChain',
            );
        });

        it('Should revert on initiate interchain token transfer when service is paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, destinationChain, destAddress, amount, '0x', gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Pause',
            );
        });

        it('Should revert on transmit send token when service is paused', async () => {
            await expectRevert(
                (gasOptions) =>
                    service.transmitInterchainTransfer(tokenId, wallet.address, destinationChain, destAddress, amount, '0x', {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });

        it('Should revert on transmit send token when destination address is zero address', async () => {
            await expectRevert(
                (gasOptions) =>
                    service.transmitInterchainTransfer(tokenId, wallet.address, destinationChain, '0x', amount, '0x', {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'TakeTokenFailed',
            );
        });

        it('Should revert on transmit send token when not called by interchain token', async () => {
            const errorSignatureHash = id('NotToken(address,address)');
            const selector = errorSignatureHash.substring(0, 10);
            const errorData = defaultAbiCoder.encode(['address', 'address'], [wallet.address, token.address]);

            await expectRevert(
                (gasOptions) =>
                    service.transmitInterchainTransfer(tokenId, wallet.address, destinationChain, destAddress, amount, '0x', {
                        ...gasOptions,
                        value: gasValue,
                    }),
                service,
                'TakeTokenFailed',
                [selector + errorData.substring(2)],
            );
        });
    });

    describe('Gateway call', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        let serviceTestGatewayCaller;

        before(async () => {
            const create3Deployer = await new ethers.ContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet)
                .deploy()
                .then((d) => d.deployed());

            const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, 'InterchainTokenService');
            const tokenManager = await deployContract(wallet, 'TokenManager', [interchainTokenServiceAddress]);
            const gatewayCaller = await deployContract(wallet, 'TestGatewayCaller');
            const interchainTokenFactoryAddress = await getCreate3Address(create3Deployer.address, wallet, 'InterchainTokenServiceFactory');

            serviceTestGatewayCaller = await deployInterchainTokenService(
                wallet,
                create3Deployer.address,
                tokenManagerDeployer.address,
                interchainTokenDeployer.address,
                gateway.address,
                gasService.address,
                interchainTokenFactoryAddress,
                tokenManager.address,
                tokenHandler.address,
                gatewayCaller.address,
                'Test',
                ITS_HUB_ADDRESS,
                [sourceChain, destinationChain],
                'InterchainTokenService',
            );
        });

        it('Should revert on initiating an interchain token transfer when gateway call failed', async () => {
            const [, , tokenId] = await deployFunctions.mintBurn(serviceTestGatewayCaller, 'Test Token', 'TG1', 12, amount);
            const metadata = '0x00000000';
            await expectRevert(
                (gasOptions) =>
                    serviceTestGatewayCaller.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, gasValue, {
                        value: gasValue,
                        ...gasOptions,
                    }),
                serviceTestGatewayCaller,
                'GatewayCallFailed',
            );
        });
    });

    describe('Execute checks', () => {
        const sourceChain = 'source chain';
        const amount = 1234;
        let destAddress;

        before(async () => {
            destAddress = wallet.address;
        });

        it('Should revert on execute if remote address validation fails', async () => {
            const commandId = await approveContractCall(gateway, sourceChain, wallet.address, service.address, '0x');

            await expectRevert(
                (gasOptions) => service.execute(commandId, sourceChain, wallet.address, '0x', gasOptions),
                service,
                'NotItsHub',
            );
        });

        it('Should revert on execute if the service is paused', async () => {
            await service.setPauseStatus(true).then((tx) => tx.wait);

            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, '0x');

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, '0x', gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });

        it('Should revert on execute with invalid messageType', async () => {
            const tokenId = getRandomBytes32();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [INVALID_MESSAGE_TYPE, tokenId, destAddress, amount],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'InvalidMessageType',
                [INVALID_MESSAGE_TYPE],
            );
        });
    });

    describe('Receive Remote Tokens', () => {
        const amount = 1234;
        let destAddress;

        before(async () => {
            destAddress = wallet.address;
        });

        it('Should revert with InvalidPayload', async () => {
            const invalidPayload = defaultAbiCoder
                .encode(['uint256', 'bytes'], [MESSAGE_TYPE_INTERCHAIN_TRANSFER, hexlify(wallet.address)])
                .slice(0, 32);
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, invalidPayload],
            );

            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'InvalidPayload',
            );
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, amount);
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(
                reportGas(
                    service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload),
                    'Receive GMP INTERCHAIN_TRANSFER lock/unlock',
                ),
            )
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, hexlify(wallet.address), destAddress, amount, HashZero);
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(service, 'Test Token Mint Burn', 'TT', 12, 0);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(
                reportGas(
                    service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload),
                    'Receive GMP INTERCHAIN_TRANSFER mint/burn',
                ),
            )
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, hexlify(wallet.address), destAddress, amount, HashZero);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                amount + 10,
            );
            await token.transfer(tokenManager.address, amount + 10).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, hexlify(wallet.address), destAddress, amount - 10, HashZero);
        });

        it('Should be able to receive lock/unlock with fee on transfer token with normal ERC20 token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                amount,
                false,
                'free',
            );
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, hexlify(wallet.address), destAddress, amount, HashZero);
        });
    });

    describe('Send Token With Data', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        let sourceAddress;
        let token, tokenManager, tokenId;

        before(async () => {
            sourceAddress = wallet.address;
            [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token lockUnlock', 'TT', 12, amount);
        });

        for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee', 'mintBurnFrom']) {
            it(`Should initiate an interchain token transfer via the interchainTransfer standard contract call & express call [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, amount * 2);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const metadata = '0x00000000';
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, destAddress, sendAmount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
                );
                const payloadHash = keccak256(wrappedPayload);

                const metadataExpress = '0x00000001';

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                if (type === 'mintBurnFrom') {
                    const txApprove = await token.approve(service.address, amount * 2);
                    await txApprove.wait();
                }

                await expect(
                    reportGas(
                        service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, gasValue, { value: gasValue }),
                        `Call service.interchainTransfer with metadata ${type}`,
                    ),
                )
                    .to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, sourceAddress, destinationChain, destAddress, sendAmount, HashZero);

                await expect(
                    reportGas(
                        service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadataExpress, gasValue, {
                            value: gasValue,
                        }),
                        `Call service.interchainTransfer with metadata ${type} (express call)`,
                    ),
                )
                    .to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForExpressCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, sourceAddress, destinationChain, destAddress, sendAmount, HashZero);
            });
        }

        for (const type of ['lockUnlock', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer via the interchainTransfer function on the service when the service is approved as well [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, amount);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const metadata = '0x00000000';
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, destAddress, sendAmount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
                );
                const payloadHash = keccak256(wrappedPayload);

                const transferToAddress = tokenManager.address;

                await token.approve(service.address, amount).then((tx) => tx.wait);
                await token.approve(tokenManager.address, 0).then((tx) => tx.wait);

                await expect(
                    reportGas(
                        service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, 0),
                        `Call service.interchainTransfer with metadata ${type}`,
                    ),
                )
                    .to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, sourceAddress, destinationChain, destAddress, sendAmount, HashZero);
            });
        }

        it('Should revert on interchainTransfer function when service is paused', async () => {
            const metadata = '0x';
            const tokenId = HashZero;

            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) => service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, 0, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });

        it('Should revert on transferToTokenManager when not called by the correct tokenManager', async () => {
            const from = otherWallet.address;

            expectRevert(
                (gasOptions) => service.transferToTokenManager(tokenId, token.address, from, amount, gasOptions),
                service,
                'NotTokenManager',
                [wallet.address, tokenManager.address],
            );
        });

        it('Should revert on interchainTransfer function with invalid metadata version', async () => {
            const metadata = '0x00000002';

            await expectRevert(
                (gasOptions) => service.interchainTransfer(tokenId, destinationChain, destAddress, amount, metadata, 0, gasOptions),
                service,
                'InvalidMetadataVersion',
                [Number(metadata)],
            );
        });
    });

    describe('Receive Remote Token with Data', () => {
        const sourceAddressForService = '0x1234';
        const amount = 1234;
        let destAddress;
        let executable;
        let invalidExecutable;

        before(async () => {
            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);
            invalidExecutable = await deployContract(wallet, 'TestInvalidInterchainExecutable', [service.address]);
            destAddress = executable.address;
        });

        it('Should be able to receive lock/unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, amount);
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddressForService, destAddress, amount, keccak256(data))
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive lock/unlock token with empty data and not call destination contract', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, amount);
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);

            const data = '0x';
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddressForService, destAddress, amount, HashZero)
                .and.to.not.emit(executable, 'MessageReceived');
        });

        it('Should be able to receive mint/burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(service, 'Test Token Mint Burn', 'TT', 12, amount);

            const msg = 'mint/burn';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(
                reportGas(
                    service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload),
                    'Receive GMP INTERCHAIN_TRANSFER_WITH_DATA mint/burn',
                ),
            )
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddressForService, destAddress, amount, keccak256(data))
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive mint/burn from token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurnFrom(service, 'Test Token Mint Burn From', 'TT', 12, amount);

            const msg = 'mint/burn';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(
                reportGas(
                    service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload),
                    'Receive GMP INTERCHAIN_TRANSFER_WITH_DATA mint/burn from',
                ),
            )
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddressForService, destAddress, amount, keccak256(data))
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive lock/unlock with fee on transfer token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                amount + 10,
            );
            await token.transfer(tokenManager.address, amount + 10).then((tx) => tx.wait);
            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, destAddress, amount)
                .to.emit(token, 'Transfer')
                .withArgs(destAddress, wallet.address, amount - 10)
                .and.to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddressForService, destAddress, amount - 10, keccak256(data))
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddressForService, wallet.address, msg, tokenId, amount - 10);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should revert if token handler transfer token from fails', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, amount);
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, AddressZero, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            const errorSignatureHash = id('TokenTransferFailed()');
            const errorData = errorSignatureHash.substring(0, 10);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'GiveTokenFailed',
                [errorData],
            );
        });

        it('Should revert if execute with interchain token fails', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, amount);
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, invalidExecutable.address, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'ExecuteWithInterchainTokenFailed',
                [invalidExecutable.address],
            );
        });

        it('Should revert with UntrustedChain when the message type is RECEIVE_FROM_HUB and untrusted original source chain', async () => {
            const data = '0x';
            const payload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, 'untrustedSourceChain', data],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, payload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payload, gasOptions),
                service,
                'UntrustedChain',
            );
        });

        it('Should revert with InvalidPayload when the message type is RECEIVE_FROM_HUB and has invalid inner payload.', async () => {
            const data = '0x';
            const sourceChain = 'hub chain 1';
            const invalidItsMessage = defaultAbiCoder
                .encode(['uint256', 'uint256', 'bytes'], [MESSAGE_TYPE_INTERCHAIN_TRANSFER, amount, data])
                .slice(0, 32);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, invalidItsMessage],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, payload);

            await expect(service.setTrustedChain(sourceChain)).to.emit(service, 'TrustedChainSet').withArgs(sourceChain);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payload, gasOptions),
                service,
                'InvalidPayload',
            );
        });

        it('Should receive a message wrapped with RECEIVE_FROM_HUB and has MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER type.', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TS';
            const tokenDecimals = 53;
            const tokenId = getRandomBytes32();

            const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                tokenId,
            ]);

            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManagerType = LOCK_UNLOCK;
            const minter = wallet.address;

            const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

            const remoteTokenAddress = '0x1234';
            const type = LOCK_UNLOCK;
            const sourceChain = 'hub chain 1';
            const itsMessage = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'uint256', 'bytes', 'bytes', 'bytes'],
                [MESSAGE_TYPE_LINK_TOKEN, tokenId, type, remoteTokenAddress, token.address, minter],
            );
            const payload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, itsMessage],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, payload);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(service.setTrustedChain(sourceChain)).to.emit(service, 'TrustedChainSet').withArgs(sourceChain);

            await expect(reportGas(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payload), 'Receive GMP DEPLOY_TOKEN_MANAGER'))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, tokenManagerType, params);

            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            expect(await tokenManager.tokenAddress()).to.equal(token.address);
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.be.true;
        });

        it('Should revert with UntrustedChain when receiving a direct message from the ITS Hub. Not supported yet', async () => {
            const data = '0x';
            const payload = defaultAbiCoder.encode(['uint256', 'bytes'], [MESSAGE_TYPE_INTERCHAIN_TRANSFER, data]);
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, ITS_HUB_CHAIN, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'UntrustedChain',
            );
        });
    });

    describe('Send Interchain Token', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        const metadata = '0x';
        let token, tokenManager, tokenId;

        for (const type of ['mintBurn', 'mintBurnFrom', 'lockUnlockFee', 'lockUnlock']) {
            it(`Should be able to initiate an interchain token transfer via interchainTransfer & interchainTransferFrom [${type}]`, async () => {
                [token, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, amount * 3, true);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, sendAmount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
                );
                const payloadHash = keccak256(wrappedPayload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(
                    reportGas(
                        token.connect(wallet).interchainTransfer(destinationChain, destAddress, amount, metadata, { value: gasValue }),
                        `Call token.interchainTransfer ${type}`,
                    ),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destinationChain, destAddress, sendAmount, HashZero);

                await token.approve(otherWallet.address, amount).then((tx) => tx.wait);

                await expect(
                    token
                        .connect(otherWallet)
                        .interchainTransferFrom(wallet.address, destinationChain, destAddress, amount, metadata, { value: gasValue }),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, otherWallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destinationChain, destAddress, sendAmount, HashZero);
            });
        }

        for (const type of ['mintBurn', 'mintBurnFrom', 'lockUnlockFee', 'lockUnlock']) {
            it(`Should be able to initiate an interchain token transfer via interchainTransfer [${type}] without native gas`, async () => {
                [token, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, amount * 3, true);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, sendAmount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
                );
                const payloadHash = keccak256(wrappedPayload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                await expect(
                    reportGas(
                        token.connect(wallet).interchainTransfer(destinationChain, destAddress, amount, metadata),
                        `Call token.interchainTransfer ${type}`,
                    ),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destinationChain, destAddress, sendAmount, HashZero);
            });
        }

        it('Should be able to initiate an interchain token transfer using interchainTransferFrom with max possible allowance', async () => {
            const sendAmount = amount;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, sendAmount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
            );
            const payloadHash = keccak256(wrappedPayload);

            const transferToAddress = tokenManager.address;

            const sender = wallet;
            const spender = otherWallet;
            await token.approve(spender.address, MaxUint256).then((tx) => tx.wait);

            await expect(
                reportGas(
                    token
                        .connect(spender)
                        .interchainTransferFrom(sender.address, destinationChain, destAddress, amount, metadata, { value: gasValue }),
                    'Call token.interchainTransferFrom lock/unlock',
                ),
            )
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, transferToAddress, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, spender.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, sender.address, destinationChain, destAddress, sendAmount, HashZero);
        });

        it('Should revert using interchainTransferFrom with zero amount', async () => {
            const sender = wallet;
            const spender = otherWallet;
            await token.approve(spender.address, MaxUint256).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) =>
                    token.connect(spender).interchainTransferFrom(sender.address, destinationChain, destAddress, 0, metadata, {
                        value: gasValue,
                        ...gasOptions,
                    }),
                service,
                'ZeroAmount',
            );
        });
    });

    describe('Send Interchain Token With Data', () => {
        const amount = 1234;
        const destAddress = '0x5678';
        let sourceAddress;
        const data = '0x1234';

        before(() => {
            sourceAddress = wallet.address;
        });

        for (const type of ['lockUnlock', 'mintBurn', 'mintBurnFrom', 'lockUnlockFee']) {
            it(`Should be able to initiate an interchain token transfer [${type}]`, async () => {
                const [token, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, amount, false);
                const sendAmount = type === 'lockUnlockFee' ? amount - 10 : amount;

                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, destAddress, sendAmount, data],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_SEND_TO_HUB, destinationChain, payload],
                );
                const payloadHash = keccak256(wrappedPayload);

                let transferToAddress = AddressZero;

                if (type === 'lockUnlock' || type === 'lockUnlockFee') {
                    transferToAddress = tokenManager.address;
                }

                const metadata = solidityPack(['uint32', 'bytes'], [0, data]);
                await expect(token.interchainTransfer(destinationChain, destAddress, amount, metadata, { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, transferToAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, wrappedPayload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, sourceAddress, destinationChain, destAddress, sendAmount, keccak256(data));
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
        let invalidExecutable;
        let token;

        before(async () => {
            [token, , tokenId] = await deployFunctions.lockUnlock(service, tokenName, tokenSymbol, tokenDecimals, amount * 2, true);
            await token.approve(service.address, amount * 2).then((tx) => tx.wait);
            data = defaultAbiCoder.encode(['address', 'string'], [destinationAddress, message]);
            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);
            invalidExecutable = await deployContract(wallet, 'TestInvalidInterchainExecutable', [service.address]);
        });

        it('Should revert on executeWithInterchainToken when not called by the service', async () => {
            await expectRevert(
                (gasOptions) =>
                    executable.executeWithInterchainToken(
                        commandId,
                        sourceChain,
                        sourceAddress,
                        data,
                        tokenId,
                        token.address,
                        amount,
                        gasOptions,
                    ),
                executable,
                'NotService',
                [wallet.address],
            );
        });

        it('Should revert on expressExecuteWithInterchainToken when not called by the service', async () => {
            await expectRevert(
                (gasOptions) =>
                    executable.expressExecuteWithInterchainToken(
                        commandId,
                        sourceChain,
                        sourceAddress,
                        data,
                        tokenId,
                        token.address,
                        amount,
                        gasOptions,
                    ),
                executable,
                'NotService',
                [wallet.address],
            );
        });

        it('Should revert on express execute when service is paused', async () => {
            const payload = '0x';

            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, sourceChain, sourceAddress, payload, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });

        it('Should express execute', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destinationAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            await expect(service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(service, 'ExpressExecuted')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, destinationAddress, amount);
        });

        it('Should revert on express execute if token handler transfer token from fails', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', ' bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, AddressZero, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const errorSignatureHash = id('TokenTransferFailed()');
            const errorData = errorSignatureHash.substring(0, 10);

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'TokenHandlerFailed',
                [errorData],
            );
        });

        it('Should revert on express execute with token if token transfer fails on destination chain', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', ' bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, invalidExecutable.address, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'ExpressExecuteWithInterchainTokenFailed',
                [invalidExecutable.address],
            );
        });

        it('Should express execute with token', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', ' bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddress, executable.address, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            await expect(service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(service, 'ExpressExecuted')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, executable.address, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(executable.address, destinationAddress, amount)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddress, destinationAddress, message, tokenId, amount);
        });
    });

    describe('Interchain Executable', () => {
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
            [token, , tokenId] = await deployFunctions.mintBurn(service, tokenName, tokenSymbol, tokenDecimals, amount * 2, true);
            data = defaultAbiCoder.encode(['address', 'string'], [destinationAddress, message]);
            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);
        });

        it('Should revert on executeWithInterchainToken when not called by the service', async () => {
            await expectRevert(
                (gasOptions) =>
                    executable.executeWithInterchainToken(
                        commandId,
                        sourceChain,
                        sourceAddress,
                        data,
                        tokenId,
                        token.address,
                        amount,
                        gasOptions,
                    ),
                executable,
                'NotService',
                [wallet.address],
            );
        });

        it('Should revert on expressExecuteWithInterchainToken when not called by the service', async () => {
            await expectRevert(
                (gasOptions) =>
                    executable.expressExecuteWithInterchainToken(
                        commandId,
                        sourceChain,
                        sourceAddress,
                        data,
                        tokenId,
                        token.address,
                        amount,
                        gasOptions,
                    ),
                executable,
                'NotService',
                [wallet.address],
            );
        });

        it('Should revert on express execute when service is paused', async () => {
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destinationAddress, amount, '0x'],
            );

            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, sourceChain, sourceAddress, payload, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });
    });

    describe('Express Receive Remote Token', () => {
        const amount = 1234;
        const destAddress = new Wallet(getRandomBytes32()).address;
        let token, tokenManager, tokenId;

        before(async () => {
            [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, 4 * amount);
        });

        it('Should revert if command is already executed by gateway', async () => {
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'AlreadyExecuted',
            );
        });

        it('Should revert with invalid messageType', async () => {
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'uint256'],
                [MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER, tokenId, destAddress, amount],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

            await expectRevert(
                (gasOptions) => service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'InvalidExpressMessageType',
                [MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER],
            );
        });

        it('Should be able to receive lock_unlock token', async () => {
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = getRandomBytes32();
            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });

        it('Should be able to receive native_interchain token', async () => {
            const [token, , tokenId] = await deployFunctions.interchainToken(service, 'Test Token Mint Burn', 'TT', 12);

            await (await token.mint(wallet.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = getRandomBytes32();

            await (await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload)).wait();
            expect(await service.getExpressExecutor(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload))).to.equal(
                wallet.address,
            );

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );
            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });

        it('Should be able to receive mint_burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(service, 'Test Token Mint Burn', 'TT', 12, amount);

            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = getRandomBytes32();

            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            expect(await service.getExpressExecutor(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload))).to.equal(
                wallet.address,
            );

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });

        it('Should be able to receive mint_burn_from token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurnFrom(service, 'Test Token Mint Burn From', 'TT', 12, amount);

            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = getRandomBytes32();

            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            expect(await service.getExpressExecutor(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload))).to.equal(
                wallet.address,
            );

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });

        it('Should be able to receive lock_unlock_with_fee token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                2 * amount + 10,
            );
            await token.transfer(tokenManager.address, amount + 10).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = getRandomBytes32();

            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            expect(await service.getExpressExecutor(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload))).to.equal(
                wallet.address,
            );

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });

        it('Should be able to receive lock_unlock_with_fee token with normal ERC20 token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                2 * amount,
                false,
                'free',
            );
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), destAddress, amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );
            const commandId = getRandomBytes32();

            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            expect(await service.getExpressExecutor(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload))).to.equal(
                wallet.address,
            );

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);
        });
    });

    describe('Express Receive Remote Token with Data', () => {
        let sourceAddress;
        const sourceAddressForService = '0x1234';
        const amount = 1234;
        let destAddress;
        let executable;

        before(async () => {
            sourceAddress = service.address;
            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);
            destAddress = executable.address;
        });

        it('Should be able to receive lock_unlock token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlock(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                amount * 2,
            );
            await token.transfer(tokenManager.address, amount).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = getRandomBytes32();
            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            const tx = service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload);
            await expect(tx)
                .to.emit(token, 'Transfer')
                .withArgs(tokenManager.address, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive native_interchain token', async () => {
            const [token, , tokenId] = await deployFunctions.interchainToken(service, 'Test Token Mint Burn', 'TT', 12);

            await (await token.mint(wallet.address, amount)).wait();
            await (await token.approve(service.address, amount)).wait();

            const msg = 'mint/burn';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = getRandomBytes32();
            await (await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload)).wait();
            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive mint_burn token', async () => {
            const [token, , tokenId] = await deployFunctions.mintBurn(service, 'Test Token Mint Burn', 'TT', 12, amount);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const msg = 'mint/burn';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const commandId = getRandomBytes32();
            await service.expressExecute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload).then((tx) => tx.wait);
            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                wrappedPayload,
                getRandomBytes32(),
                0,
                commandId,
            );

            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload))
                .to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, amount)
                .and.to.emit(service, 'ExpressExecutionFulfilled')
                .withArgs(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, keccak256(wrappedPayload), wallet.address);

            expect(await executable.lastMessage()).to.equal(msg);
        });

        it('Should be able to receive lock_unlock_with_fee token', async () => {
            const [token, tokenManager, tokenId] = await deployFunctions.lockUnlockFee(
                service,
                'Test Token Lock Unlock',
                'TT',
                12,
                amount * 2 + 10,
            );
            await token.transfer(tokenManager.address, amount + 10).then((tx) => tx.wait);
            await token.approve(service.address, amount).then((tx) => tx.wait);

            const msg = 'lock/unlock';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, msg]);
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, sourceAddressForService, destAddress, amount, data],
            );
            const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

            await expect(service.expressExecute(commandId, sourceChain, sourceAddress, payload)).to.be.reverted;
        });
    });

    describe('Flow Limits', () => {
        const destinationAddress = '0x1234';
        let tokenManager, tokenId;
        const sendAmount = 1234;
        const flowLimit = (sendAmount * 3) / 2;
        const mintAmount = MaxUint256;

        before(async () => {
            [, tokenManager, tokenId] = await deployFunctions.mintBurn(service, 'Test Token Lock Unlock', 'TT', 12, mintAmount);
            await tokenManager.setFlowLimit(flowLimit).then((tx) => tx.wait);
        });

        it('Should be able to send token only if it does not trigger the mint limit', async () => {
            await service.interchainTransfer(tokenId, destinationChain, destinationAddress, sendAmount, '0x', 0).then((tx) => tx.wait);

            const errorSignatureHash = id('FlowLimitExceeded(uint256,uint256,address)');
            const selector = errorSignatureHash.substring(0, 10);
            const errorData = defaultAbiCoder.encode(['uint256', 'uint256', 'address'], [flowLimit, 2 * sendAmount, tokenManager.address]);

            await expectRevert(
                (gasOptions) => service.interchainTransfer(tokenId, destinationChain, destinationAddress, sendAmount, '0x', 0, gasOptions),
                service,
                'TakeTokenFailed',
                [selector + errorData.substring(2)],
            );
        });

        it('Should be able to receive token only if it does not trigger the mint limit', async () => {
            const tokenManager = await getContractAt('ITokenManager', await service.deployedTokenManager(tokenId), wallet);
            const tokenFlowLimit = await tokenManager.flowLimit();
            expect(tokenFlowLimit).to.eq(flowLimit);

            let flowIn = await tokenManager.flowInAmount();
            let flowOut = await tokenManager.flowOutAmount();

            expect(flowIn).to.eq(0);
            expect(flowOut).to.eq(sendAmount);

            async function receiveToken(amount) {
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), wallet.address, amount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
                );
                const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

                return service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload);
            }

            await receiveToken(sendAmount).then((tx) => tx.wait);

            flowIn = await tokenManager.flowInAmount();
            flowOut = await tokenManager.flowOutAmount();

            expect(flowIn).to.eq(sendAmount);
            expect(flowOut).to.eq(sendAmount);

            const errorSignatureHash = id('FlowLimitExceeded(uint256,uint256,address)');
            const selector = errorSignatureHash.substring(0, 10);
            const errorData = defaultAbiCoder.encode(
                ['uint256', 'uint256', 'address'],
                [(5 * sendAmount) / 2, 3 * sendAmount, tokenManager.address],
            );

            await expectRevert((gasOptions) => receiveToken(2 * sendAmount, gasOptions), service, 'GiveTokenFailed', [
                selector + errorData.substring(2),
            ]);
        });

        it('Should revert if the flow limit overflows', async () => {
            const tokenManager = await getContractAt('ITokenManager', await service.deployedTokenManager(tokenId), wallet);
            const tokenFlowLimit = await tokenManager.flowLimit();
            expect(tokenFlowLimit).to.eq(flowLimit);

            const flowIn = await tokenManager.flowInAmount();
            const flowOut = await tokenManager.flowOutAmount();

            expect(flowIn).to.eq(sendAmount);
            expect(flowOut).to.eq(sendAmount);

            const newSendAmount = 1;
            const newFlowLimit = MaxUint256;

            await tokenManager.setFlowLimit(newFlowLimit).then((tx) => tx.wait);

            async function receiveToken(amount) {
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                    [MESSAGE_TYPE_INTERCHAIN_TRANSFER, tokenId, hexlify(wallet.address), wallet.address, amount, '0x'],
                );
                const wrappedPayload = defaultAbiCoder.encode(
                    ['uint256', 'string', 'bytes'],
                    [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
                );
                const commandId = await approveContractCall(gateway, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, service.address, wrappedPayload);

                return service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload);
            }

            const errorSignatureHash = id('FlowLimitOverflow(uint256,uint256,address)');
            const selector = errorSignatureHash.substring(0, 10);
            const errorData = defaultAbiCoder.encode(['uint256', 'uint256', 'address'], [newFlowLimit, flowIn, tokenManager.address]);

            await expectRevert((gasOptions) => receiveToken(newSendAmount, gasOptions), service, 'GiveTokenFailed', [
                selector + errorData.substring(2),
            ]);
        });

        it('Should revert if the flow addition overflows', async () => {
            const tokenManager = await getContractAt('ITokenManager', await service.deployedTokenManager(tokenId), wallet);
            const tokenFlowLimit = await tokenManager.flowLimit();
            expect(tokenFlowLimit).to.eq(MaxUint256);

            const flowIn = await tokenManager.flowInAmount();
            const flowOut = await tokenManager.flowOutAmount();

            expect(flowIn).to.eq(sendAmount);
            expect(flowOut).to.eq(sendAmount);

            const newSendAmount = MaxUint256;

            const errorSignatureHash = id('FlowAdditionOverflow(uint256,uint256,address)');
            const selector = errorSignatureHash.substring(0, 10);
            const errorData = defaultAbiCoder.encode(['uint256', 'uint256', 'address'], [newSendAmount, flowOut, tokenManager.address]);

            await expectRevert(
                (gasOptions) =>
                    service.interchainTransfer(tokenId, destinationChain, destinationAddress, newSendAmount, '0x', 0, gasOptions),
                service,
                'TakeTokenFailed',
                [selector + errorData.substring(2)],
            );
        });

        it('Should be able to set flow limits for each token manager', async () => {
            const tokenIds = [];
            const tokenManagers = [];

            for (const type of ['lockUnlock', 'mintBurn', 'lockUnlockFee']) {
                const [, tokenManager, tokenId] = await deployFunctions[type](service, `Test Token ${type}`, 'TT', 12, mintAmount);
                tokenIds.push(tokenId);
                tokenManagers.push(tokenManager);
            }

            const flowLimits = new Array(tokenManagers.length).fill(flowLimit);

            await expectRevert(
                (gasOptions) => service.connect(otherWallet).setFlowLimits(tokenIds, flowLimits, gasOptions),
                service,
                'MissingRole',
                [otherWallet.address, OPERATOR_ROLE],
            );

            await expect(service.setFlowLimits(tokenIds, flowLimits))
                .to.emit(tokenManagers[0], 'FlowLimitSet')
                .withArgs(tokenIds[0], service.address, flowLimit)
                .to.emit(tokenManagers[1], 'FlowLimitSet')
                .withArgs(tokenIds[1], service.address, flowLimit)
                .to.emit(tokenManagers[2], 'FlowLimitSet')
                .withArgs(tokenIds[2], service.address, flowLimit);

            flowLimits.pop();

            await expectRevert((gasOptions) => service.setFlowLimits(tokenIds, flowLimits, gasOptions), service, 'LengthMismatch');
        });
    });

    describe('Flow Limiters', () => {
        let tokenManager;
        const sendAmount = 1234;
        const flowLimit = (sendAmount * 3) / 2;
        const mintAmount = flowLimit * 3;

        before(async () => {
            [, tokenManager] = await deployFunctions.mintBurn(service, 'Test Token Lock Unlock', 'TT', 12, mintAmount);
        });

        it('Should have only the owner be a flow limiter', async () => {
            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
        });

        it('Should be able to add a flow limiter', async () => {
            await expect(tokenManager.addFlowLimiter(otherWallet.address))
                .to.emit(tokenManager, 'RolesAdded')
                .withArgs(otherWallet.address, 1 << FLOW_LIMITER_ROLE);

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
        });

        it('Should be able to remove a flow limiter', async () => {
            await expect(tokenManager.removeFlowLimiter(wallet.address))
                .to.emit(tokenManager, 'RolesRemoved')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE);

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
        });

        it('Should be able to transfer a flow limiter', async () => {
            await expect(tokenManager.transferFlowLimiter(otherWallet.address, wallet.address))
                .to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .to.emit(tokenManager, 'RolesRemoved')
                .withArgs(otherWallet.address, 1 << FLOW_LIMITER_ROLE);

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(false);

            await expectRevert(
                (gasOptions) => tokenManager.transferFlowLimiter(otherWallet.address, wallet.address, gasOptions),
                tokenManager,
                'MissingAllRoles',
                [otherWallet.address, 1 << FLOW_LIMITER_ROLE],
            );
        });

        it('Should revert if trying to add a flow limiter as not the operator', async () => {
            await expectRevert(
                (gasOptions) => tokenManager.connect(otherWallet).addFlowLimiter(otherWallet.address, gasOptions),
                tokenManager,
                'MissingRole',
                [otherWallet.address, OPERATOR_ROLE],
            );
        });

        it('Should revert if trying to add a flow limiter as not the operator', async () => {
            await expectRevert(
                (gasOptions) => tokenManager.connect(otherWallet).removeFlowLimiter(wallet.address, gasOptions),
                tokenManager,
                'MissingRole',
                [otherWallet.address, OPERATOR_ROLE],
            );
        });

        it('Should be able to transfer a flow limiter and the operator in one call', async () => {
            const tx1Data = (await tokenManager.populateTransaction.transferFlowLimiter(wallet.address, otherWallet.address)).data;
            const tx2Data = (await tokenManager.populateTransaction.transferOperatorship(otherWallet.address)).data;
            await expect(tokenManager.multicall([tx1Data, tx2Data]))
                .to.emit(tokenManager, 'RolesAdded')
                .withArgs(otherWallet.address, 1 << FLOW_LIMITER_ROLE)
                .to.emit(tokenManager, 'RolesRemoved')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .to.emit(tokenManager, 'RolesAdded')
                .withArgs(otherWallet.address, 1 << OPERATOR_ROLE)
                .to.emit(tokenManager, 'RolesRemoved')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE);

            expect(await tokenManager.hasRole(wallet.address, FLOW_LIMITER_ROLE)).to.equal(false);
            expect(await tokenManager.hasRole(otherWallet.address, FLOW_LIMITER_ROLE)).to.equal(true);
            expect(await tokenManager.hasRole(wallet.address, OPERATOR_ROLE)).to.equal(false);
            expect(await tokenManager.hasRole(otherWallet.address, OPERATOR_ROLE)).to.equal(true);
        });
    });

    describe('Call contract value', () => {
        const untrustedAddress = 'untrusted address';
        const amount = 100;

        it('Should revert on contractCallValue if not called by remote service', async () => {
            const payload = '0x';

            await expectRevert(
                (gasOptions) => service.contractCallValue(sourceChain, untrustedAddress, payload, gasOptions),
                service,
                'NotItsHub',
            );
        });

        it('Should revert on contractCallValue if service is paused', async () => {
            const payload = '0x';

            await service.setPauseStatus(true).then((tx) => tx.wait);

            await expectRevert(
                (gasOptions) => service.contractCallValue(ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payload, gasOptions),
                service,
                'Pause',
            );

            await service.setPauseStatus(false).then((tx) => tx.wait);
        });

        it('Should revert on invalid express message type', async () => {
            const message = 10;
            const tokenId = HashZero;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [message, tokenId, '0x', '0x', amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            await expectRevert(
                (gasOptions) => service.contractCallValue(ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload, gasOptions),
                service,
                'InvalidExpressMessageType',
                [message],
            );
        });

        it('Should return correct token address and amount', async () => {
            const mintAmount = 1234;
            const [token, , tokenId] = await deployFunctions.lockUnlock(service, 'Test Token Lock Unlock', 'TT', 12, mintAmount);
            const message = 0;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'bytes', 'bytes', 'uint256', 'bytes'],
                [message, tokenId, '0x', '0x', amount, '0x'],
            );
            const wrappedPayload = defaultAbiCoder.encode(
                ['uint256', 'string', 'bytes'],
                [MESSAGE_TYPE_RECEIVE_FROM_HUB, sourceChain, payload],
            );

            const [tokenAddress, returnedAmount] = await service.contractCallValue(ITS_HUB_CHAIN, ITS_HUB_ADDRESS, wrappedPayload);

            expect(tokenAddress).to.eq(token.address);
            expect(returnedAmount).to.eq(amount);
        });
    });

    describe('Interchain Token Migration', () => {
        it('Should migrate a token succesfully', async () => {
            const name = 'migrated token';
            const symbol = 'MT';
            const decimals = 53;

            const [token, tokenManager, tokenId] = await deployFunctions.interchainToken(service, name, symbol, decimals, service.address);

            await expect(service.migrateInterchainToken(tokenId))
                .to.emit(token, 'RolesRemoved')
                .withArgs(service.address, 1 << MINTER_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(tokenManager.address, 1 << MINTER_ROLE);
        });

        it('Should not be able to migrate a token twice', async () => {
            const name = 'migrated token';
            const symbol = 'MT';
            const decimals = 53;

            const [token, tokenManager, tokenId] = await deployFunctions.interchainToken(service, name, symbol, decimals, service.address);

            await expect(service.migrateInterchainToken(tokenId))
                .to.emit(token, 'RolesRemoved')
                .withArgs(service.address, 1 << MINTER_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(tokenManager.address, 1 << MINTER_ROLE);

            await expectRevert((gasOptions) => service.migrateInterchainToken(tokenId, { gasOptions }), token, 'MissingRole', [
                service.address,
                MINTER_ROLE,
            ]);
        });

        it('Should not be able to migrate a token as not the owner', async () => {
            const name = 'migrated token';
            const symbol = 'MT';
            const decimals = 53;

            const [, , tokenId] = await deployFunctions.interchainToken(service, name, symbol, decimals, service.address);

            await expectRevert(
                (gasOptions) => service.connect(otherWallet).migrateInterchainToken(tokenId, gasOptions),
                service,
                'NotOwner',
            );
        });
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same proxy bytecode for each EVM', async () => {
            const proxyFactory = await ethers.getContractFactory('InterchainProxy', wallet);
            const proxyBytecode = proxyFactory.bytecode;
            const proxyBytecodeHash = keccak256(proxyBytecode);

            const expected = {
                london: '0x57e9041ac230850afa53b1373118c6e6649eed78a7731296b62fc8455d49b4ef',
            }[getEVMVersion()];

            expect(proxyBytecodeHash).to.be.equal(expected);
        });
    });
});
