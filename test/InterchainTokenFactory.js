'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers, network } = require('hardhat');
const {
    getContractAt,
    Wallet,
    constants: { AddressZero, HashZero },
    utils: { defaultAbiCoder, keccak256, toUtf8Bytes, arrayify },
} = ethers;
const { deployAll, deployContract } = require('../scripts/deploy');
const {
    getRandomBytes32,
    expectRevert,
    gasReporter,
    encodeDeployInterchainTokenMessage,
    encodeSendHubMessage,
    encodeLinkTokenMessage,
    expectNonZeroAddress,
} = require('./utils');
const {
    NATIVE_INTERCHAIN_TOKEN,
    LOCK_UNLOCK,
    MINT_BURN,
    MINT_BURN_FROM,
    LOCK_UNLOCK_FEE_ON_TRANSFER,
    ITS_HUB_CHAIN,
    ITS_HUB_ADDRESS,
    DEPLOY_REMOTE_INTERCHAIN_TOKEN,
    DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER,
    DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN,
    DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN,
} = require('./constants');
const { getBytecodeHash } = require('@axelar-network/axelar-chains-config');

const { createHtsToken } = require('../scripts/create-hts-token.js');
const { hederaClientFromHardhatConfig } = require('../scripts/hedera-client.js');

const reportGas = gasReporter('Interchain Token Factory');

describe.only('InterchainTokenFactory', () => {
    let wallet, otherWallet;
    let service, gateway, gasService, tokenFactory;
    const chainName = 'Test';
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    let hederaClient, hederaPk;
    before(() => {
        const hederaClientInfo = hederaClientFromHardhatConfig(network.config);
        hederaClient = hederaClientInfo.hederaClient;
        hederaPk = hederaClientInfo.hederaPk;
    });

    before(async () => {
        [wallet, otherWallet] = await ethers.getSigners();
        ({ service, gateway, gasService, tokenFactory } = await deployAll(wallet, chainName, ITS_HUB_ADDRESS, [destinationChain]));
    });

    describe('Token Factory Deployment', async () => {
        it('Should revert on invalid interchain token service address', async () => {
            await expectRevert(
                (gasOptions) => deployContract(wallet, 'InterchainTokenFactory', [AddressZero, gasOptions]),
                tokenFactory,
                'ZeroAddress',
            );
        });

        it('Should return the correct contract ID', async () => {
            const expectedContractid = keccak256(toUtf8Bytes('interchain-token-factory'));
            const contractId = await tokenFactory.contractId();
            expect(contractId).to.eq(expectedContractid);
        });
    });

    describe('Upgrade', async () => {
        it('Should revert on upgrade from non-owner account', async () => {
            await expectRevert(
                (gasOptions) => tokenFactory.connect(otherWallet).upgrade(AddressZero, HashZero, '0x', gasOptions),
                tokenFactory,
                'NotOwner',
            );
        });

        it('Should upgrade the implementation', async () => {
            const newImplementation = await deployContract(wallet, 'InterchainTokenFactory', [service.address]);
            const newImplementationCodeHash = await getBytecodeHash(newImplementation);
            const setupParams = '0x';

            await expect(tokenFactory.upgrade(newImplementation.address, newImplementationCodeHash, setupParams))
                .to.emit(tokenFactory, 'Upgraded')
                .withArgs(newImplementation.address);

            expect(await tokenFactory.implementation()).to.eq(newImplementation.address);
        });

        it('Should upgrade the implementation with setup data', async () => {
            const newImplementation = await deployContract(wallet, 'InterchainTokenFactory', [service.address]);
            const newImplementationCodeHash = await getBytecodeHash(newImplementation);
            const setupParams = '0x1234';

            await expect(tokenFactory.upgrade(newImplementation.address, newImplementationCodeHash, setupParams))
                .to.emit(tokenFactory, 'Upgraded')
                .withArgs(newImplementation.address);

            expect(await tokenFactory.implementation()).to.eq(newImplementation.address);
        });
    });

    describe('Canonical Interchain Token Factory', async () => {
        let token, tokenId, tokenManagerAddress;
        const tokenCap = BigInt(1e18);

        async function deployToken() {
            const [tokenAddress] = await createHtsToken(hederaClient, hederaPk, name, symbol, decimals, tokenCap);
            token = await getContractAt('IERC20Named', tokenAddress, wallet);
            tokenId = await tokenFactory.canonicalInterchainTokenId(token.address);
            tokenManagerAddress = await service.tokenManagerAddress(tokenId);
        }

        before(async () => {
            await deployToken();
        });

        it('Should register a token', async () => {
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerCanonicalInterchainToken(token.address))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
        });

        it('Should not register a non-existing token', async () => {
            await expectRevert(
                (gasOptions) => tokenFactory.registerCanonicalInterchainToken(tokenFactory.address, { gasOptions }),
                tokenFactory,
                'NotToken',
                [tokenFactory.address],
            );
        });

        it('Should initiate a remote interchain token deployment with no original chain name provided', async () => {
            const gasValue = 1234;
            const { payload, payloadHash } = encodeSendHubMessage(
                destinationChain,
                encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x'),
            );

            await expect(
                tokenFactory[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN]('', token.address, destinationChain, gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);

            await expect(
                tokenFactory[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN](token.address, destinationChain, gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
        });

        it('Should initiate a remote interchain token deployment', async () => {
            const gasValue = 1234;
            const { payload, payloadHash } = encodeSendHubMessage(
                destinationChain,
                encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x'),
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN](
                        chainName,
                        token.address,
                        destinationChain,
                        gasValue,
                        {
                            value: gasValue * 10 ** 10,
                        },
                    ),
                tokenFactory,
                'NotSupported',
            );

            await expect(
                tokenFactory[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN](token.address, destinationChain, gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
        });
    });

    describe('Interchain Token Factory', async () => {
        let tokenId;
        const mintAmount = 1234;
        const minter = new Wallet(getRandomBytes32()).address;

        const checkRoles = async (tokenManager, minter) => {
            expect(await tokenManager.isMinter(minter)).to.be.true;

            expect(await tokenManager.isOperator(minter)).to.be.true;
            expect(await tokenManager.isOperator(service.address)).to.be.true;

            expect(await tokenManager.isFlowLimiter(minter)).to.be.true;
            expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;
        };

        it('Should revert an interchain token deployment with the minter as interchainTokenService', async () => {
            const salt = keccak256('0x1245');
            await expectRevert(
                (gasOptions) => tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, service.address, gasOptions),
                tokenFactory,
                'InvalidMinter',
                [service.address],
            );
        });

        it('Should register a token if the mint amount is zero', async () => {
            const salt = keccak256('0x1234');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', expectedTokenManagerAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                });

            await checkRoles(tokenManager, minter);
        });

        it('Should revert when trying to register a token if the mint amount is zero and minter is the zero address', async () => {
            const salt = keccak256('0x123456');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);

            await expectRevert(
                (gasOptions) => tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, AddressZero, { gasOptions }),
                tokenFactory,
                'ZeroSupplyToken',
                [],
            );
        });

        it.skip('Should register a token if the mint amount is greater than zero and the minter is the zero address [unsupported]', async () => {
            const salt = keccak256('0x12345678');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', expectedTokenManagerAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                });

            await checkRoles(tokenManager, AddressZero);
        });

        it('Should register a token', async () => {
            const mintAmount = 0;

            const salt = keccak256('0x');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                });

            const tokenManager = await getContractAt('TokenManager', expectedTokenManagerAddress, wallet);
            // Get token address from the deployed token manager
            const tokenAddress = await tokenManager.tokenAddress();
            const token = await getContractAt('IERC20Named', tokenAddress, wallet);

            expect(await token.balanceOf(tokenFactory.address)).to.equal(0);
            expect(await token.balanceOf(wallet.address)).to.equal(mintAmount);

            await checkRoles(tokenManager, minter);
        });

        it('Should initiate a remote interchain token deployment with the same minter', async () => {
            const gasValue = 1234;
            const mintAmount = 0;

            const salt = keccak256('0x12');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const minter = wallet.address;

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                });

            const { payload, payloadHash } = encodeSendHubMessage(
                destinationChain,
                encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, wallet.address.toLowerCase()),
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER](
                        chainName,
                        salt,
                        otherWallet.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue * 10 ** 10,
                        },
                    ),
                tokenFactory,
                'NotSupported',
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER](
                        '',
                        salt,
                        otherWallet.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue * 10 ** 10,
                        },
                    ),
                tokenFactory,
                'NotMinter',
                [otherWallet.address],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER](
                        '',
                        salt,
                        service.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue * 10 ** 10,
                        },
                    ),
                tokenFactory,
                'NotMinter',
                [service.address],
            );

            await expect(
                tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER](
                    '',
                    salt,
                    wallet.address,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue * 10 ** 10,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.deployRemoteInterchainTokenWithMinter(salt, wallet.address, destinationChain, wallet.address, gasValue, {
                        ...gasOptions,
                        value: gasValue * 10 ** 10,
                    }),
                tokenFactory,
                'RemoteDeploymentNotApproved',
                [],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.deployRemoteInterchainTokenWithMinter(salt, AddressZero, destinationChain, wallet.address, gasValue, {
                        ...gasOptions,
                        value: gasValue * 10 ** 10,
                    }),
                tokenFactory,
                'InvalidMinter',
                [AddressZero],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.approveDeployRemoteInterchainToken(wallet.address, salt, 'untrusted-chain', wallet.address, gasOptions),
                tokenFactory,
                'InvalidChainName',
                [],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory
                        .connect(otherWallet)
                        .approveDeployRemoteInterchainToken(wallet.address, salt, destinationChain, wallet.address, gasOptions),
                tokenFactory,
                'NotMinter',
                [otherWallet.address],
            );

            await expect(tokenFactory.approveDeployRemoteInterchainToken(wallet.address, salt, destinationChain, wallet.address))
                .to.emit(tokenFactory, 'DeployRemoteInterchainTokenApproval')
                .withArgs(wallet.address, wallet.address, tokenId, destinationChain, arrayify(wallet.address));

            await expect(tokenFactory.revokeDeployRemoteInterchainToken(wallet.address, salt, destinationChain))
                .to.emit(tokenFactory, 'RevokedDeployRemoteInterchainTokenApproval')
                .withArgs(wallet.address, wallet.address, tokenId, destinationChain);

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.deployRemoteInterchainTokenWithMinter(salt, wallet.address, destinationChain, wallet.address, gasValue, {
                        ...gasOptions,
                        value: gasValue * 10 ** 10,
                    }),
                tokenFactory,
                'RemoteDeploymentNotApproved',
                [],
            );

            await expect(tokenFactory.approveDeployRemoteInterchainToken(wallet.address, salt, destinationChain, wallet.address))
                .to.emit(tokenFactory, 'DeployRemoteInterchainTokenApproval')
                .withArgs(wallet.address, wallet.address, tokenId, destinationChain, arrayify(wallet.address));

            await expect(
                tokenFactory.deployRemoteInterchainTokenWithMinter(salt, wallet.address, destinationChain, wallet.address, gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
        });

        it('Should initiate a remote interchain token deployment without the same minter', async () => {
            const gasValue = 1234;
            const mintAmount = 0;

            const salt = keccak256('0x1245');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const minter = wallet.address;

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                });

            // Get token address and check roles/transfers
            // const tokenAddress = await tokenManager.tokenAddress();

            const { payload, payloadHash } = encodeSendHubMessage(
                destinationChain,
                encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x'),
            );

            await expect(
                tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN_WITH_ORIGINAL_CHAIN_NAME_AND_MINTER](
                    '',
                    salt,
                    AddressZero,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue * 10 ** 10,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);

            await expect(
                tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN](salt, destinationChain, gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);

            await expect(
                tokenFactory.deployRemoteInterchainTokenWithMinter(salt, AddressZero, destinationChain, '0x', gasValue, {
                    value: gasValue * 10 ** 10,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
        });

        it('Should revert when deploying a remote interchain token to self', async () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            const salt = getRandomBytes32();

            await tokenFactory
                .deployInterchainToken(salt, tokenName, tokenSymbol, tokenDecimals, 0, wallet.address)
                .then((tx) => tx.wait());

            await expectRevert(
                (gasOptions) => tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN](salt, chainName, 0, gasOptions),
                service,
                'CannotDeployRemotelyToSelf',
            );
        });

        it('Should revert when deploying an interchain token with initial supply', async () => {
            const salt = getRandomBytes32();
            const tokenName = 'name';
            const tokenDecimals = 9;
            const initailSupply = 1000;

            await expectRevert(
                (gasOptions) => tokenFactory.deployInterchainToken(salt, tokenName, '', tokenDecimals, initailSupply, minter, gasOptions),
                tokenFactory,
                'InitialSupplyUnsupported',
            );
        });

        it('Should revert on remote interchain token deployment with invalid token symbol', async () => {
            const salt = getRandomBytes32();
            const tokenName = 'name';
            const tokenDecimals = 9;

            await expectRevert(
                (gasOptions) => tokenFactory.deployInterchainToken(salt, tokenName, '', tokenDecimals, 0, minter, gasOptions),
                service,
                'EmptyTokenSymbol',
            );
        });

        it('Should revert on remote interchain token deployment if destination chain is not trusted', async () => {
            const salt = getRandomBytes32();
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 8;

            await tokenFactory
                .deployInterchainToken(salt, tokenName, tokenSymbol, tokenDecimals, 0, wallet.address, { gasLimit: 1000000 })
                .then((tx) => tx.wait());

            await expectRevert(
                (gasOptions) => tokenFactory[DEPLOY_REMOTE_INTERCHAIN_TOKEN](salt, 'untrusted chain', 0, gasOptions),
                service,
                'UntrustedChain',
            );
        });

        it('Should revert on remote interchain token deployment with invalid token name', async () => {
            const salt = getRandomBytes32();
            const tokenSymbol = 'symbol';
            const tokenDecimals = 9;

            await expectRevert(
                (gasOptions) => tokenFactory.deployInterchainToken(salt, '', tokenSymbol, tokenDecimals, 0, minter, gasOptions),
                service,
                'EmptyTokenName',
            );
        });

        describe('Custom Token Manager Deployment', () => {
            const tokenName = 'Token Name';
            const tokenSymbol = 'TN';
            const tokenDecimals = 13;
            let token, salt, tokenId;
            let tokenManagerProxy;
            let factorySalt;

            before(async () => {
                salt = getRandomBytes32();
                tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const [tokenAddress] = await createHtsToken(hederaClient, hederaPk, name, symbol, decimals, 0);
                token = await getContractAt('IERC20Named', tokenAddress, wallet);
                factorySalt = await tokenFactory.linkedTokenDeploySalt(wallet.address, salt);
            });

            it('Should revert on deploying an invalid token manager', async () => {
                await expectRevert((gasOptions) => tokenFactory.registerCustomToken(salt, token.address, 6, wallet.address, gasOptions));
            });

            it('Should revert on deploying a local token manager with interchain token manager type', async () => {
                await expectRevert(
                    (gasOptions) =>
                        tokenFactory.registerCustomToken(salt, token.address, NATIVE_INTERCHAIN_TOKEN, wallet.address, gasOptions),
                    service,
                    'CannotDeploy',
                    [NATIVE_INTERCHAIN_TOKEN],
                );
            });

            it('Should revert on deploying a remote token manager with interchain token manager type', async () => {
                await expectRevert(
                    (gasOptions) =>
                        tokenFactory.linkToken(
                            salt,
                            destinationChain,
                            token.address,
                            NATIVE_INTERCHAIN_TOKEN,
                            wallet.address,
                            0,
                            gasOptions,
                        ),
                    service,
                    'CannotDeploy',
                    [NATIVE_INTERCHAIN_TOKEN],
                );
            });

            it('Should revert on deploying a token manager if token handler post deploy fails', async () => {
                await expectRevert(
                    (gasOptions) => tokenFactory.registerCustomToken(salt, AddressZero, LOCK_UNLOCK, wallet.address, gasOptions),
                    service,
                    'PostDeployFailed',
                );
            });

            it('Should revert when deploying a custom token when the service is paused', async () => {
                const salt = getRandomBytes32();

                await service.setPauseStatus(true).then((tx) => tx.wait());

                await expectRevert(
                    (gasOptions) => tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK, AddressZero, gasOptions),
                    service,
                    'Pause',
                );

                await service.setPauseStatus(false).then((tx) => tx.wait());
            });

            it('Should register a custom token with no operator', async () => {
                const salt = getRandomBytes32();
                const tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const deploySalt = await tokenFactory.linkedTokenDeploySalt(wallet.address, salt);
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

                await expect(tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK, AddressZero))
                    .to.emit(service, 'InterchainTokenIdClaimed')
                    .withArgs(tokenId, AddressZero, deploySalt)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
            });

            it('Should register a custom token with a custom operator', async () => {
                const salt = getRandomBytes32();
                const tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const deploySalt = await tokenFactory.linkedTokenDeploySalt(wallet.address, salt);
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

                await expect(tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK, wallet.address))
                    .to.emit(service, 'InterchainTokenIdClaimed')
                    .withArgs(tokenId, AddressZero, deploySalt)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);
            });

            it('Should register a token with lock_unlock type', async () => {
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

                await expect(
                    reportGas(
                        tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK, wallet.address),
                        'Call deployTokenManager on source chain',
                    ),
                )
                    .to.emit(service, 'InterchainTokenIdClaimed')
                    .withArgs(tokenId, AddressZero, factorySalt)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, tokenManagerAddress, LOCK_UNLOCK, params);

                expect(tokenManagerAddress).to.not.equal(AddressZero);
                const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

                expect(await tokenManager.isOperator(wallet.address)).to.be.true;
                expect(await tokenManager.isOperator(service.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(wallet.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;

                const tokenAddress = await service.registeredTokenAddress(tokenId);
                expect(tokenAddress.toLowerCase()).to.eq(token.address.toLowerCase());

                tokenManagerProxy = await getContractAt('TokenManagerProxy', tokenManagerAddress, wallet);

                const [implementation, tokenAddressFromProxy] = await tokenManagerProxy.getImplementationTypeAndTokenAddress();
                expect(implementation).to.eq(LOCK_UNLOCK);
                expect(tokenAddressFromProxy.toLowerCase()).to.eq(token.address.toLowerCase());
            });

            it('Should revert when linking a token twice', async () => {
                const revertData = keccak256(toUtf8Bytes('AlreadyDeployed()')).substring(0, 10);
                await expectRevert(
                    (gasOptions) => tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK, wallet.address, gasOptions),
                    service,
                    'TokenManagerDeploymentFailed',
                    [revertData],
                );
            });

            it('Should revert when calling unsupported functions directly on the token manager implementation', async () => {
                const implementationAddress = await tokenManagerProxy.implementation();
                const implementationContract = await getContractAt('TokenManager', implementationAddress, wallet);
                await expectRevert((gasOptions) => implementationContract.tokenAddress(gasOptions), implementationContract, 'NotSupported');
                await expectRevert(
                    (gasOptions) => implementationContract.interchainTokenId(gasOptions),
                    implementationContract,
                    'NotSupported',
                );
                await expectRevert(
                    (gasOptions) => implementationContract.implementationType(gasOptions),
                    implementationContract,
                    'NotSupported',
                );
            });

            it.skip('Should register a token with mint_burn type [unsupported]', async () => {
                const salt = getRandomBytes32();
                const tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    service.address,
                    tokenId,
                ]);
                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

                const tx = tokenFactory.registerCustomToken(salt, token.address, MINT_BURN, wallet.address);
                const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
                await expect(tx).to.emit(service, 'TokenManagerDeployed').withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);

                expect(tokenManagerAddress).to.not.equal(AddressZero);
                const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

                expect(await tokenManager.isOperator(wallet.address)).to.be.true;
                expect(await tokenManager.isOperator(service.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(wallet.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;

                const tokenAddress = await service.registeredTokenAddress(tokenId);
                expect(tokenAddress).to.eq(token.address);

                const tokenManagerProxy = await getContractAt('TokenManagerProxy', tokenManagerAddress, wallet);

                const [implementation, tokenAddressFromProxy] = await tokenManagerProxy.getImplementationTypeAndTokenAddress();
                expect(implementation).to.eq(MINT_BURN);
                expect(tokenAddressFromProxy).to.eq(token.address);
            });

            it.skip('Should register a token with mint_burn_from type [unsupported]', async () => {
                const salt = getRandomBytes32();
                const tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    service.address,
                    tokenId,
                ]);
                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

                const tx = tokenFactory.registerCustomToken(salt, token.address, MINT_BURN_FROM, wallet.address);
                const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
                await expect(tx)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN_FROM, params);

                expect(tokenManagerAddress).to.not.equal(AddressZero);
                const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

                expect(await tokenManager.isOperator(wallet.address)).to.be.true;
                expect(await tokenManager.isOperator(service.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(wallet.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;

                const tokenAddress = await service.registeredTokenAddress(tokenId);
                expect(tokenAddress).to.eq(token.address);

                const tokenManagerProxy = await getContractAt('TokenManagerProxy', tokenManagerAddress, wallet);

                const [implementation, tokenAddressFromProxy] = await tokenManagerProxy.getImplementationTypeAndTokenAddress();
                expect(implementation).to.eq(MINT_BURN_FROM);
                expect(tokenAddressFromProxy).to.eq(token.address);
            });

            it('Should register a token with lock_unlock_with_fee type', async () => {
                const salt = getRandomBytes32();
                const tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
                const token = await deployContract(wallet, 'TestFeeOnTransferToken', [
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    service.address,
                    tokenId,
                ]);
                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

                const tx = tokenFactory.registerCustomToken(salt, token.address, LOCK_UNLOCK_FEE_ON_TRANSFER, wallet.address);
                const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);
                await expect(tx)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, LOCK_UNLOCK_FEE_ON_TRANSFER, params);

                expect(tokenManagerAddress).to.not.equal(AddressZero);
                const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);

                expect(await tokenManager.isOperator(wallet.address)).to.be.true;
                expect(await tokenManager.isOperator(service.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(wallet.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;

                const tokenAddress = await service.registeredTokenAddress(tokenId);
                expect(tokenAddress).to.eq(token.address);

                const tokenManagerProxy = await getContractAt('TokenManagerProxy', tokenManagerAddress, wallet);

                const [implementation, tokenAddressFromProxy] = await tokenManagerProxy.getImplementationTypeAndTokenAddress();
                expect(implementation).to.eq(LOCK_UNLOCK_FEE_ON_TRANSFER);
                expect(tokenAddressFromProxy).to.eq(token.address);
            });

            it('Should revert on registering a token if ITS is paused', async () => {
                await service.setPauseStatus(true).then((tx) => tx.wait());

                await expectRevert(
                    (gasOptions) => tokenFactory.linkToken(salt, '', token.address, LOCK_UNLOCK, wallet.address, 0, gasOptions),
                    service,
                    'Pause',
                );

                await service.setPauseStatus(false).then((tx) => tx.wait());
            });
        });

        describe('Initialize remote custom token manager deployment', () => {
            let token, tokenId, salt;
            const tokenManagerType = LOCK_UNLOCK;
            const operator = AddressZero;
            const gasValue = 5678;

            async function deployAndRegisterToken() {
                salt = getRandomBytes32();

                const [tokenAddress] = await createHtsToken(hederaClient, hederaPk, name, symbol, decimals, 0);
                token = await getContractAt('IERC20Named', tokenAddress, wallet);

                tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
                await tokenFactory.registerCustomToken(salt, token.address, tokenManagerType, operator).then((tx) => tx.wait());
            }

            it('Should initialize a remote custom token manager deployment', async () => {
                await deployAndRegisterToken();

                const remoteTokenAddress = '0x1234';
                const minter = '0x5789';
                const type = LOCK_UNLOCK;
                const { payload, payloadHash } = encodeSendHubMessage(
                    destinationChain,
                    encodeLinkTokenMessage(tokenId, type, token.address, remoteTokenAddress, minter),
                );
                const tokenManager = await getContractAt('TokenManager', await service.deployedTokenManager(tokenId), wallet);
                expect(await tokenManager.isOperator(AddressZero)).to.be.true;
                expect(await tokenManager.isOperator(service.address)).to.be.true;
                expect(await tokenManager.isFlowLimiter(AddressZero)).to.be.true;
                expect(await tokenManager.isFlowLimiter(service.address)).to.be.true;

                await expect(
                    reportGas(
                        tokenFactory.linkToken(salt, destinationChain, remoteTokenAddress, type, minter, gasValue, {
                            value: gasValue * 10 ** 10,
                        }),
                        'Send deployTokenManager to remote chain',
                    ),
                )
                    .to.emit(service, 'InterchainTokenIdClaimed')
                    .withArgs(tokenId, AddressZero, await tokenFactory.linkedTokenDeploySalt(wallet.address, salt))
                    .to.emit(service, 'LinkTokenStarted')
                    .withArgs(
                        tokenId,
                        destinationChain,
                        token.address.toLowerCase(),
                        remoteTokenAddress.toLowerCase(),
                        type,
                        minter.toLowerCase(),
                    )
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
            });

            it('Should revert on a remote custom token manager deployment if the token manager does not exist', async () => {
                const salt = getRandomBytes32();
                const tokenId = await service.interchainTokenId(wallet.address, salt);
                const tokenAddress = '0x1234';
                const minter = '0x5678';
                const type = LOCK_UNLOCK;

                await expect(
                    tokenFactory.linkToken(salt, destinationChain, tokenAddress, type, minter, gasValue, { value: gasValue * 10 ** 10 }),
                ).to.be.revertedWithCustomError(service, 'TokenManagerDoesNotExist', [tokenId]);
            });

            it('Should revert on remote custom token manager deployment if paused', async () => {
                await service.setPauseStatus(true).then((tx) => tx.wait());

                const salt = getRandomBytes32();
                const tokenAddress = '0x1234';
                const minter = '0x5678';
                const type = LOCK_UNLOCK;

                await expectRevert(
                    (gasOptions) =>
                        tokenFactory.linkToken(salt, destinationChain, tokenAddress, type, minter, gasValue, {
                            ...gasOptions,
                            value: gasValue * 10 ** 10,
                        }),
                    service,
                    'Pause',
                );

                await service.setPauseStatus(false).then((tx) => tx.wait());
            });
        });
    });
});
