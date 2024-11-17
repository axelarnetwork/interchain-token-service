'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const {
    getContractAt,
    Wallet,
    constants: { AddressZero, HashZero },
    utils: { defaultAbiCoder, keccak256, toUtf8Bytes, arrayify },
} = ethers;
const { deployAll, deployContract } = require('../scripts/deploy');
const { getRandomBytes32, expectRevert } = require('./utils');
const {
    MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN,
    NATIVE_INTERCHAIN_TOKEN,
    LOCK_UNLOCK,
    MINTER_ROLE,
    OPERATOR_ROLE,
    FLOW_LIMITER_ROLE,
} = require('./constants');
const { getBytecodeHash } = require('@axelar-network/axelar-chains-config');

describe('InterchainTokenFactory', () => {
    let wallet, otherWallet;
    let service, gateway, gasService, tokenFactory;
    const chainName = 'Test';
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const destinationChain = 'destination chain';

    before(async () => {
        [wallet, otherWallet] = await ethers.getSigners();
        ({ service, gateway, gasService, tokenFactory } = await deployAll(wallet, chainName, [destinationChain]));
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
            token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                name,
                symbol,
                decimals,
                service.address,
                getRandomBytes32(),
            ]);
            tokenId = await tokenFactory.canonicalInterchainTokenId(token.address);
            tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            await token.mint(wallet.address, tokenCap).then((tx) => tx.wait);
            await token.setTokenId(tokenId).then((tx) => tx.wait);
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

        it('Should initiate a remote interchain token deployment with no original chain name provided', async () => {
            const gasValue = 1234;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );

            await expect(
                tokenFactory['deployRemoteCanonicalInterchainToken(string,address,string,uint256)'](
                    '',
                    token.address,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expect(
                tokenFactory['deployRemoteCanonicalInterchainToken(address,string,uint256)'](token.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should initiate a remote interchain token deployment', async () => {
            const gasValue = 1234;
            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteCanonicalInterchainToken(string,address,string,uint256)'](
                        chainName,
                        token.address,
                        destinationChain,
                        gasValue,
                        {
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'NotSupported',
            );

            await expect(
                tokenFactory['deployRemoteCanonicalInterchainToken(address,string,uint256)'](token.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });
    });

    describe('Interchain Token Factory', async () => {
        let tokenId;
        const mintAmount = 1234;
        const minter = new Wallet(getRandomBytes32()).address;

        const checkRoles = async (tokenManager, minter) => {
            const token = await getContractAt('InterchainToken', await tokenManager.tokenAddress(), wallet);
            expect(await token.isMinter(minter)).to.be.true;
            expect(await token.isMinter(service.address)).to.be.true;

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
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [minter, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params);

            await checkRoles(tokenManager, minter);
        });

        it('Should register a token if the mint amount is zero and minter is the zero address', async () => {
            const salt = keccak256('0x123456');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const minterBytes = new Uint8Array();
            const params = defaultAbiCoder.encode(['bytes', 'address'], [minterBytes, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, AddressZero, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params);

            await checkRoles(tokenManager, AddressZero);
        });

        it('Should register a token if the mint amount is greater than zero and the minter is the zero address', async () => {
            const salt = keccak256('0x12345678');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params);

            await checkRoles(tokenManager, AddressZero);
        });

        it('Should register a token', async () => {
            const salt = keccak256('0x');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, mintAmount)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(minter, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(minter, 1 << OPERATOR_ROLE)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(minter, 1 << MINTER_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << MINTER_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            expect(await token.balanceOf(tokenFactory.address)).to.equal(0);
            expect(await token.balanceOf(wallet.address)).to.equal(mintAmount);

            await checkRoles(tokenManager, minter);
        });

        it('Should initiate a remote interchain token deployment with the same minter', async () => {
            const gasValue = 1234;
            const mintAmount = 5678;

            const salt = keccak256('0x12');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << MINTER_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << MINTER_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, wallet.address.toLowerCase()],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteInterchainToken(string,bytes32,address,string,uint256)'](
                        chainName,
                        salt,
                        otherWallet.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'NotSupported',
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteInterchainToken(string,bytes32,address,string,uint256)'](
                        '',
                        salt,
                        otherWallet.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'NotMinter',
                [otherWallet.address],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteInterchainToken(string,bytes32,address,string,uint256)'](
                        '',
                        salt,
                        service.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'InvalidMinter',
                [service.address],
            );

            await expect(
                tokenFactory['deployRemoteInterchainToken(string,bytes32,address,string,uint256)'](
                    '',
                    salt,
                    wallet.address,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteInterchainToken(bytes32,address,string,uint256)'](
                        salt,
                        otherWallet.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'NotMinter',
                [otherWallet.address],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory['deployRemoteInterchainToken(bytes32,address,string,uint256)'](
                        salt,
                        service.address,
                        destinationChain,
                        gasValue,
                        {
                            ...gasOptions,
                            value: gasValue,
                        },
                    ),
                tokenFactory,
                'InvalidMinter',
                [service.address],
            );

            await expect(
                tokenFactory['deployRemoteInterchainToken(bytes32,address,string,uint256)'](
                    salt,
                    wallet.address,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.deployRemoteInterchainTokenWithMinter(salt, wallet.address, destinationChain, wallet.address, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                tokenFactory,
                'RemoteDeploymentNotApproved',
                [],
            );

            await expectRevert(
                (gasOptions) =>
                    tokenFactory.deployRemoteInterchainTokenWithMinter(salt, AddressZero, destinationChain, wallet.address, gasValue, {
                        ...gasOptions,
                        value: gasValue,
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
                        value: gasValue,
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
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });

        it('Should initiate a remote interchain token deployment without the same minter', async () => {
            const gasValue = 1234;

            const salt = keccak256('0x1245');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await service.interchainTokenAddress(tokenId);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, NATIVE_INTERCHAIN_TOKEN, params)
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, wallet.address, mintAmount)
                .and.to.emit(token, 'RolesAdded')
                .withArgs(wallet.address, 1 << MINTER_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesAdded')
                .withArgs(wallet.address, 1 << FLOW_LIMITER_ROLE)
                .and.to.emit(token, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << MINTER_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << OPERATOR_ROLE)
                .and.to.emit(tokenManager, 'RolesRemoved')
                .withArgs(tokenFactory.address, 1 << FLOW_LIMITER_ROLE);

            const payload = defaultAbiCoder.encode(
                ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, name, symbol, decimals, '0x'],
            );

            await expect(
                tokenFactory['deployRemoteInterchainToken(string,bytes32,address,string,uint256)'](
                    '',
                    salt,
                    AddressZero,
                    destinationChain,
                    gasValue,
                    {
                        value: gasValue,
                    },
                ),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expect(
                tokenFactory['deployRemoteInterchainToken(bytes32,address,string,uint256)'](salt, AddressZero, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expect(
                tokenFactory.deployRemoteInterchainTokenWithMinter(salt, AddressZero, destinationChain, '0x', gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);
        });
    });
});
