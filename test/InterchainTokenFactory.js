'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const {
    getContractAt,
    Wallet,
    constants: { AddressZero },
    utils: { defaultAbiCoder, keccak256, toUtf8Bytes },
} = ethers;
const { deployAll, deployContract } = require('../scripts/deploy');
const { getRandomBytes32, expectRevert } = require('./utils');

const MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 1;

const LOCK_UNLOCK = 2;
const MINT_BURN = 0;
const GATEWAY = 4;

const MINTER_ROLE = 0;
const OPERATOR_ROLE = 1;
const FLOW_LIMITER_ROLE = 2;

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
            await (await token.mint(wallet.address, tokenCap)).wait();
            await (await token.setTokenId(tokenId)).wait();
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
                tokenFactory.deployRemoteCanonicalInterchainToken('', token.address, destinationChain, gasValue, {
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

            await expect(
                tokenFactory.deployRemoteCanonicalInterchainToken(chainName, token.address, destinationChain, gasValue, {
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

        it('Should revert when trying to register a canonical lock/unlock gateway token', async () => {
            const tokenCap = 0;
            const mintLimit = 0;
            const tokenAddress = token.address;

            const params = defaultAbiCoder.encode(
                ['string', 'string', 'uint8', 'uint256', 'address', 'uint256'],
                [name, symbol, decimals, tokenCap, tokenAddress, mintLimit],
            );
            await (await gateway.deployToken(params, getRandomBytes32())).wait();

            await expectRevert(
                (gasOptions) => tokenFactory.registerCanonicalInterchainToken(tokenAddress, gasOptions),
                tokenFactory,
                'GatewayToken',
                [tokenAddress],
            );
        });

        it('Should revert when trying to register a canonical mint/burn gateway token', async () => {
            const tokenCap = 0;
            let tokenAddress = AddressZero;
            const mintLimit = 0;
            const newSymbol = 'NewSymbol';
            const params = defaultAbiCoder.encode(
                ['string', 'string', 'uint8', 'uint256', 'address', 'uint256'],
                [name, newSymbol, decimals, tokenCap, tokenAddress, mintLimit],
            );
            await (await gateway.deployToken(params, getRandomBytes32())).wait();

            tokenAddress = await gateway.tokenAddresses(newSymbol);

            await expectRevert(
                (gasOptions) => tokenFactory.registerCanonicalInterchainToken(tokenAddress, gasOptions),
                tokenFactory,
                'GatewayToken',
                [tokenAddress],
            );
        });
    });

    describe('Gateway Interchain Token Factory', async () => {
        let token, tokenId, tokenManagerAddress, symbol;
        const tokenCap = BigInt(1e18);

        async function deployToken(salt, lockUnlock = true) {
            let tokenAddress = AddressZero;

            if (lockUnlock) {
                token = await deployContract(wallet, 'TestInterchainTokenStandard', [
                    name,
                    symbol,
                    decimals,
                    service.address,
                    getRandomBytes32(),
                ]);
                tokenAddress = token.address;
            }

            const params = defaultAbiCoder.encode(
                ['string', 'string', 'uint8', 'uint256', 'address', 'uint256'],
                [name, symbol, decimals, 0, tokenAddress, 0],
            );

            await (await gateway.deployToken(params, getRandomBytes32())).wait();

            tokenId = await service.interchainTokenId(AddressZero, salt);
            tokenManagerAddress = await service.tokenManagerAddress(tokenId);

            if (lockUnlock) {
                await (await token.mint(wallet.address, tokenCap)).wait();
                await (await token.setTokenId(tokenId)).wait();
            } else {
                tokenAddress = await gateway.tokenAddresses(symbol);
                token = await getContractAt('IERC20', tokenAddress);
                await await gateway.mintToken(
                    defaultAbiCoder.encode(['string', 'address', 'uint256'], [symbol, wallet.address, tokenCap]),
                    getRandomBytes32(),
                );
            }
        }

        it('Should register a token lock/unlock gateway token', async () => {
            const salt = getRandomBytes32();
            symbol = 'TT0';
            await deployToken(salt, true);
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerGatewayToken(salt, symbol))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, GATEWAY, params);
        });

        it('Should register a token mint/burn gateway token', async () => {
            const salt = getRandomBytes32();
            symbol = 'TT1';
            await deployToken(salt, false);
            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', token.address]);

            await expect(tokenFactory.registerGatewayToken(salt, symbol))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManagerAddress, GATEWAY, params);
        });

        it('Should revert when trying to register a gateway token that does not exist', async () => {
            const salt = getRandomBytes32();
            const symbol = 'TT2';

            await expectRevert((gasOptions) => tokenFactory.registerGatewayToken(salt, symbol), tokenFactory, 'NotGatewayToken', [symbol]);
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

        it('Should register a token if the mint amount is zero', async () => {
            const salt = keccak256('0x1234');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [minter, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params);

            await checkRoles(tokenManager, minter);
        });

        it('Should register a token if the mint amount is zero and minter is the zero address', async () => {
            const salt = keccak256('0x123456');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const minterBytes = new Uint8Array();
            const params = defaultAbiCoder.encode(['bytes', 'address'], [minterBytes, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, AddressZero, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params);

            await checkRoles(tokenManager, AddressZero);
        });

        it('Should register a token if the mint amount is greater than zero and the minter is the zero address', async () => {
            const salt = keccak256('0x12345678');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params);

            await checkRoles(tokenManager, AddressZero);
        });

        it('Should register a token', async () => {
            const salt = keccak256('0x');
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, minter))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
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
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
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
                    tokenFactory.deployRemoteInterchainToken(chainName, salt, otherWallet.address, destinationChain, gasValue, {
                        ...gasOptions,
                        value: gasValue,
                    }),
                tokenFactory,
                'NotMinter',
                [otherWallet.address],
            );

            await expect(
                tokenFactory.deployRemoteInterchainToken('', salt, wallet.address, destinationChain, gasValue, {
                    value: gasValue,
                }),
            )
                .to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), destinationChain)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), gasValue, wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, destinationChain, service.address, keccak256(payload), payload);

            await expect(
                tokenFactory.deployRemoteInterchainToken(chainName, salt, wallet.address, destinationChain, gasValue, {
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
            const tokenAddress = await tokenFactory.interchainTokenAddress(wallet.address, salt);
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, tokenAddress]);
            const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);
            const token = await getContractAt('InterchainToken', tokenAddress, wallet);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, mintAmount, wallet.address))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, tokenAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, tokenManager.address, MINT_BURN, params)
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
                tokenFactory.deployRemoteInterchainToken(chainName, salt, AddressZero, destinationChain, gasValue, {
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
