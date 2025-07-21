'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers, network } = require('hardhat');
const { AddressZero } = ethers.constants;

const {
    getContractAt,
    Wallet,
    constants: { HashZero },
    utils: { defaultAbiCoder, keccak256, solidityPack, arrayify },
} = ethers;

const {
    getRandomBytes32,
    expectRevert,
    encodeInterchainTransferMessage,
    encodeDeployInterchainTokenMessage,
    encodeSendHubMessage,
    encodeReceiveHubMessage,
    encodeLinkTokenMessage,
    encodeRegisterTokenMetadataMessage,
    expectNonZeroAddress,
} = require('./utils');
const { deployAll, deployContract } = require('../scripts/deploy');
const { approveContractCall } = require('../scripts/utils');
const {
    NATIVE_INTERCHAIN_TOKEN,
    LOCK_UNLOCK,
    MINT_BURN,
    MINTER_ROLE,
    ITS_HUB_CHAIN,
    ITS_HUB_ADDRESS,
    DEPLOY_REMOTE_INTERCHAIN_TOKEN,
    DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN,
    INTERCHAIN_TRANSFER,
    INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE,
} = require('./constants');

const { createHtsToken } = require('../scripts/create-hts-token.js');
const { hederaClientFromHardhatConfig } = require('../scripts/hedera-client.js');

describe.only('Interchain Token Service Full Flow', () => {
    let wallet;
    let service, gateway, gasService, tokenFactory, tokenId;
    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const otherChains = ['chain 1', 'chain 2'];
    const decimals = 6;
    const chainName = 'Test';

    let hederaClient, hederaPk;
    before(() => {
        const hederaClientInfo = hederaClientFromHardhatConfig(network.config);
        hederaClient = hederaClientInfo.hederaClient;
        hederaPk = hederaClientInfo.hederaPk;
    });

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        ({ service, gateway, gasService, tokenFactory } = await deployAll(wallet, chainName, ITS_HUB_ADDRESS, otherChains));
    });

    /**
     * This test deploys Canonical Interchain tokens for a pre-existing token on remote chains via the InterchainTokenFactory and multicall.
     * Canonical tokens are registered under Lock/Unlock token manager on local chain, and mint/burn on remote chains.
     * They can be deployed to remote chains by anyone, and don't depend on a deployer address/salt.
     * - Register pre-existing token as Canonical
     * - Deploy Canonical Interchain token to each remote chain via the factory
     * - Transfer tokens via ITS between chains after deployment
     */
    // Hedera ✅
    describe('Canonical Interchain Token', () => {
        let erc20TokenId, htsTokenId;
        let erc20Token, htsToken;
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;
        const transferAmount = 1e6;

        before(async () => {
            // Any ERC20 can be used here
            erc20Token = await deployContract(wallet, 'TestMintableBurnableERC20', [name, symbol, decimals]);
            await erc20Token.mint(wallet.address, tokenCap + transferAmount).then((tx) => tx.wait());

            const [htsTokenAddress] = await createHtsToken(hederaClient, hederaPk, name, symbol, decimals, tokenCap);
            htsToken = await getContractAt('IERC20Named', htsTokenAddress, wallet);
        });

        it('Should register the token and initiate its deployment on other chains [ERC20]', async () => {
            const tokenId = await tokenFactory.canonicalInterchainTokenId(erc20Token.address);

            let tx = await tokenFactory.populateTransaction.registerCanonicalInterchainToken(erc20Token.address);
            const calls = [tx.data];
            let value = 0;

            for (const i in otherChains) {
                tx = await tokenFactory.populateTransaction[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN](
                    erc20Token.address,
                    otherChains[i],
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', erc20Token.address]);
            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x')),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await tokenFactory.multicall(calls, { value: value * 10 ** 10 });

            await expect(multicall)
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, LOCK_UNLOCK, params)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);

            erc20TokenId = tokenId;
        });

        it('Should register the token and initiate its deployment on other chains [HTS]', async () => {
            const tokenId = await tokenFactory.canonicalInterchainTokenId(htsToken.address);

            let tx = await tokenFactory.populateTransaction.registerCanonicalInterchainToken(htsToken.address);
            const calls = [tx.data];
            let value = 0;

            for (const i in otherChains) {
                tx = await tokenFactory.populateTransaction[DEPLOY_REMOTE_CANONICAL_INTERCHAIN_TOKEN](
                    htsToken.address,
                    otherChains[i],
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const params = defaultAbiCoder.encode(['bytes', 'address'], ['0x', htsToken.address]);
            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x')),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await tokenFactory.multicall(calls, { value: value * 10 ** 10 });

            await expect(multicall)
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, LOCK_UNLOCK, params)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);

            htsTokenId = tokenId;
        });

        describe('Interchain transfer', () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            it('Should send some tokens to another chain via ITS [ERC20]', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(erc20TokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );
                const tokenManagerAddress = await service.tokenManagerAddress(erc20TokenId);

                // Canonical (pre-existing) token requires an approval due to locking
                await expect(erc20Token.approve(service.address, amount))
                    .to.emit(erc20Token, 'Approval')
                    .withArgs(wallet.address, service.address, amount);

                await expect(
                    service[INTERCHAIN_TRANSFER](erc20TokenId, destChain, destAddress, amount, {
                        value: gasValue * 10 ** 10,
                    }),
                )
                    .and.to.emit(erc20Token, 'Transfer')
                    .withArgs(wallet.address, tokenManagerAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(erc20TokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });

            it('Should send some tokens to another chain via ITS [HTS]', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(htsTokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );
                const tokenManagerAddress = await service.tokenManagerAddress(htsTokenId);

                // Canonical (pre-existing) token requires an approval due to locking
                await expect(htsToken.approve(service.address, amount))
                    .to.emit(htsToken, 'Approval')
                    .withArgs(wallet.address, service.address, amount);

                await expect(
                    service[INTERCHAIN_TRANSFER](htsTokenId, destChain, destAddress, amount, {
                        value: gasValue * 10 ** 10,
                    }),
                )
                    .and.to.emit(htsToken, 'Transfer')
                    .withArgs(wallet.address, tokenManagerAddress, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(htsTokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });
        });
    });

    /**
     * This test deploys brand new Interchain tokens to all chains via the InterchainTokenFactory and multicall:
     * - Deploy new Interchain token on local chain via the factory with an initial supply
     * - Deploy new Interchain token to each remote chain via the factory
     * - Transfer token via native method on the token
     * - Transfer tokens via ITS between chains after deployment
     * - Transfers mint/burn role from original deployer wallet to another address
     */
    describe('New Interchain token', () => {
        let token;
        let tokenId;
        const salt = getRandomBytes32();
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;

        before(async () => {
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);

            // Deploy token first to get address
            await tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, wallet.address);
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            const tokenAddress = await tokenManager.tokenAddress();
            token = await getContractAt('IERC20Named', tokenAddress, wallet);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const totalMint = tokenCap;
            const minter = wallet.address;

            // Deploy a new Interchain token on the local chain.
            let tx = await tokenFactory.populateTransaction.deployInterchainToken(salt, name, symbol, decimals, totalMint, minter);
            const calls = [tx.data];
            let value = 0;

            // Deploy a linked Interchain token to remote chains.
            for (const i in otherChains) {
                tx = await tokenFactory.populateTransaction['deployRemoteInterchainTokenWithMinter(bytes32,address,string,bytes,uint256)'](
                    salt,
                    minter,
                    otherChains[i],
                    '0x',
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, minter)),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await tokenFactory.multicall(calls, { value });
            await expect(multicall)
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, minter, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                })
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, minter.toLowerCase(), otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, wallet.address.toLowerCase(), otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);

            expect(await token.balanceOf(wallet.address)).to.equal(totalMint);

            expect(await service.deployedTokenManager(tokenId)).to.equal(expectedTokenManagerAddress);
        });

        describe('Interchain transfer', () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            it('Should send some tokens to another chain via the token', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(tokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );

                await expect(token.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });

            it('Should send some tokens to another chain via ITS', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(tokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );

                await expect(
                    service[INTERCHAIN_TRANSFER](tokenId, destChain, destAddress, amount, {
                        value: gasValue * 10 ** 10,
                    }),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });

            it('Should send some tokens to multiple chains via ITS', async () => {
                const calls = [];
                const destAddress = arrayify(wallet.address);
                let value = 0;

                for (const i in otherChains) {
                    const tx = await service.populateTransaction[INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE](
                        tokenId,
                        otherChains[i],
                        destAddress,
                        amount,
                        '0x',
                        gasValues[i],
                    );
                    calls.push(tx.data);
                    value += gasValues[i];
                }

                const payloads = otherChains.map((chain) =>
                    encodeSendHubMessage(chain, encodeInterchainTransferMessage(tokenId, wallet.address, destAddress, amount, '0x')),
                );

                const multicall = await service.multicall(calls, { value });
                await expect(multicall)
                    .to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                    .and.to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, otherChains[0], destAddress, amount, HashZero)
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                    .and.to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, otherChains[1], destAddress, amount, HashZero);
            });
        });

        /**
         * Change the minter to another address
         */
        it('Should be able to change the token minter', async () => {
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferMintership(newAddress))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << MINTER_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(newAddress, 1 << MINTER_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                MINTER_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                MINTER_ROLE,
            ]);
        });
    });

    /**
     * This test creates a token link between pre-existing tokens by giving mint/burn permission to ITS.
     * - Choose the tokens being linked across chains. For the test, a mint/burn ERC20 is deployed for the source chain.
     * - Register token metadata of the token on each chain being linked via ITS
     * - Link the source chain token to each remote token via ITS Factory
     * - Give/transfer mint/burn permission to the corresponding token manager on each chain
     * - Transfer tokens via ITS between chains
     */
    describe('Pre-existing Token as Mint/Burn', () => {
        let token;
        const otherChains = ['chain 1', 'chain 2'];
        const gasValues = [1234, 5678];
        const registrationGasValue = 1234;
        const tokenCap = 1e9;
        const salt = getRandomBytes32();

        before(async () => {
            token = await deployContract(wallet, 'TestMintableBurnableERC20', [name, symbol, decimals]);

            tokenId = await tokenFactory.linkedTokenId(wallet.address, salt);
            await token.mint(wallet.address, tokenCap).then((tx) => tx.wait());
        });

        it('Should register token metadata', async () => {
            const { payload, payloadHash } = encodeRegisterTokenMetadataMessage(token.address, decimals);

            // Register token metadata being linked from the source chain
            // Similarly, submit this registration from ITS contract of all chains for the corresponding token addresses being linked
            await expect(service.registerTokenMetadata(token.address, registrationGasValue, { value: registrationGasValue }))
                .to.emit(service, 'TokenMetadataRegistered')
                .withArgs(token.address, decimals)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload);
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const tokenManagerImplementationAddress = await service.tokenManager();
            const tokenManagerImplementation = await getContractAt('TokenManager', tokenManagerImplementationAddress, wallet);

            const params = await tokenManagerImplementation.params(wallet.address, token.address);
            let tx = await tokenFactory.populateTransaction.registerCustomToken(salt, token.address, MINT_BURN, wallet.address);
            const calls = [tx.data];
            let value = 0;

            for (const i in otherChains) {
                // This should be replaced with the existing token address on each chain being linked
                const remoteTokenAddress = token.address;

                tx = await tokenFactory.populateTransaction.linkToken(
                    salt,
                    otherChains[i],
                    remoteTokenAddress,
                    MINT_BURN,
                    wallet.address,
                    gasValues[i],
                    { value: gasValues[i] },
                );

                calls.push(tx.data);
                value += gasValues[i];
            }

            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeLinkTokenMessage(tokenId, MINT_BURN, token.address, token.address, wallet.address)),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(tokenFactory.multicall(calls, { value }))
                .to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params)
                .and.to.emit(service, 'LinkTokenStarted')
                .withArgs(
                    tokenId,
                    otherChains[0],
                    token.address.toLowerCase(),
                    token.address.toLowerCase(),
                    MINT_BURN,
                    wallet.address.toLowerCase(),
                )
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'LinkTokenStarted')
                .withArgs(
                    tokenId,
                    otherChains[1],
                    token.address.toLowerCase(),
                    token.address.toLowerCase(),
                    MINT_BURN,
                    wallet.address.toLowerCase(),
                )
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);
        });

        /**
         * Transfer the minter to ITS on all chains to allow it to mint/burn
         */
        it('Should be able to change the token minter', async () => {
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const newAddress = new Wallet(getRandomBytes32()).address;
            const amount = 1234;

            await expect(token.mint(newAddress, amount)).to.emit(token, 'Transfer').withArgs(AddressZero, newAddress, amount);
            await expect(token.burn(newAddress, amount)).to.emit(token, 'Transfer').withArgs(newAddress, AddressZero, amount);

            await expect(token.transferMintership(tokenManagerAddress))
                .to.emit(token, 'RolesRemoved')
                .withArgs(wallet.address, 1 << MINTER_ROLE)
                .to.emit(token, 'RolesAdded')
                .withArgs(tokenManagerAddress, 1 << MINTER_ROLE);

            await expectRevert((gasOptions) => token.mint(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                MINTER_ROLE,
            ]);
            await expectRevert((gasOptions) => token.burn(newAddress, amount, gasOptions), token, 'MissingRole', [
                wallet.address,
                MINTER_ROLE,
            ]);
        });

        /**
         * Send an interchain transfer. To receive the tokens, the receiving ITS
         * also needs to have the mint/burn permission.
         */
        describe('Interchain transfer', () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            it('Should send some tokens to another chain via ITS', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(tokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );

                await expect(
                    service[INTERCHAIN_TRANSFER](tokenId, destChain, destAddress, amount, {
                        value: gasValue * 10 ** 10,
                    }),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });
        });
    });

    /**
     * This test deploys a fixed supply InterchainToken
     * - Deploy an InterchainToken without a minter and a fixed supply
     * - Deploy the InterchainToken to additional chains
     * - Transfer from the fixed supply to additional chains
     * - Transfer tokens via ITS between chains
     */
    describe('Fixed Supply Interchain Token', () => {
        let token;
        let tokenId;
        const salt = getRandomBytes32();
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;
        const totalMint = (1 + otherChains.length) * tokenCap;

        before(async () => {
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);

            // Deploy token first to get address
            await tokenFactory.deployInterchainToken(salt, name, symbol, decimals, totalMint, AddressZero);
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            const tokenAddress = await tokenManager.tokenAddress();
            token = await getContractAt('IERC20Named', tokenAddress, wallet);
        });

        // To get a fixed supply InterchainToken, simply set the minter to address(0) during deployment.
        it('Should deploy the token and deploy on other chains', async () => {
            // Deploy a new Interchain token on the local chain.
            // The initial mint occurs on the factory contract, so it can be moved to other chains within the same multicall.
            let tx = await tokenFactory.populateTransaction.deployInterchainToken(salt, name, symbol, decimals, totalMint, AddressZero);
            const calls = [tx.data];
            let value = 0;

            // Deploy a linked Interchain token to remote chains.
            for (const i in otherChains) {
                tx = await tokenFactory.populateTransaction[DEPLOY_REMOTE_INTERCHAIN_TOKEN](salt, otherChains[i], gasValues[i]);
                calls.push(tx.data);
                value += gasValues[i];
            }

            const minter = '0x';
            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, minter)),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await tokenFactory.multicall(calls, { value });
            await expect(multicall)
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(tokenId, expectedTokenManagerAddress, NATIVE_INTERCHAIN_TOKEN, (params) => {
                    const [operator, tokenAddress_] = defaultAbiCoder.decode(['bytes', 'address'], params);
                    expect(operator.toLowerCase()).to.equal(minter.toLowerCase());
                    expectNonZeroAddress(tokenAddress_);
                    return true;
                })
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);

            // Only tokens minted for the local chain should be left, remaining should be burned.
            expect(await token.balanceOf(wallet.address)).to.equal(totalMint);

            expect(await service.deployedTokenManager(tokenId)).to.equal(expectedTokenManagerAddress);
        });

        // After the remote deployments are complete we transfer the initial supply to them.
        it('Should transfer from the fixed supply to both other chains', async () => {
            const calls = [];
            const destAddress = arrayify(wallet.address);
            let value = 0;

            for (const i in otherChains) {
                const tx = await service.populateTransaction[INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE](
                    tokenId,
                    otherChains[i],
                    destAddress,
                    tokenCap,
                    '0x',
                    gasValues[i],
                );
                calls.push(tx.data);
                value += gasValues[i];
            }

            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeInterchainTransferMessage(tokenId, wallet.address, destAddress, tokenCap, '0x')),
            );

            const multicall = await service.multicall(calls, { value });
            await expect(multicall)
                .to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, tokenCap)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, wallet.address, otherChains[0], destAddress, tokenCap, HashZero)
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, tokenCap)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, wallet.address, otherChains[1], destAddress, tokenCap, HashZero);

            expect(await token.balanceOf(wallet.address)).to.equal(totalMint - otherChains.length * tokenCap);
        });
    });

    /**
     * This test deploys an InterchainToken and an InterchainExecutable, which then receives an InterchainTransfer with data
     * - Deploy an InterchainToken and the Executable
     * - Call the executable with an interchain transfer
     * - Execute the application, TestInterchainExecutable
     */
    describe('Executable Example', () => {
        let token, tokenId, executable;
        const totalMint = 1e9;

        before(async () => {
            const salt = getRandomBytes32();
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            await expect(tokenFactory.deployInterchainToken(salt, name, symbol, decimals, totalMint, AddressZero))
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(
                    tokenId,
                    expectedTokenManagerAddress,
                    NATIVE_INTERCHAIN_TOKEN,
                    validateTokenManagerParams('NATIVE_INTERCHAIN_TOKEN', tokenFactory.address, name, symbol, decimals),
                );

            // Get token address from deployed token manager
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            const tokenAddress = await tokenManager.tokenAddress();
            token = await getContractAt('IERC20Named', tokenAddress, wallet);
            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);
        });

        it('Should execute an application with interchain transfer', async () => {
            const sourceChain = otherChains[0];
            const destChain = otherChains[1];
            const sourceAddress = arrayify(wallet.address);
            const amount = 1234;
            const gasValue = 6789; // Set this to the gas quote for the interchain call in production

            const message = 'Hello World!';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, message]);
            const metadataVersion = 0;
            const metadata = solidityPack(['uint32', 'bytes'], [metadataVersion, data]);
            const outgoingMessage = encodeInterchainTransferMessage(tokenId, sourceAddress, executable.address, amount, data);
            const outgoingPayload = encodeSendHubMessage(destChain, outgoingMessage);
            const incomingMessage = encodeInterchainTransferMessage(tokenId, sourceAddress, executable.address, amount, data);
            const incomingPayload = encodeReceiveHubMessage(sourceChain, incomingMessage);
            const commandId = getRandomBytes32();

            // Initiate the contract call with transfer
            await expect(
                service[INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE](
                    tokenId,
                    destChain,
                    executable.address,
                    amount,
                    metadata,
                    gasValue,
                    { value: gasValue },
                ),
            )
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, outgoingPayload.payloadHash, outgoingPayload.payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, outgoingPayload.payloadHash, gasValue, wallet.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, wallet.address, destChain, executable.address.toLowerCase(), amount, keccak256(data));

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                incomingPayload.payload,
                getRandomBytes32(),
                0,
                commandId,
            );

            // Execute the contract call on destination with transfer
            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, incomingPayload.payload))
                .to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddress, executable.address, amount, keccak256(data))
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, executable.address, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(executable.address, wallet.address, amount)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddress, wallet.address, message, tokenId, amount);
        });
    });

    /**
     * This test deploys brand new Interchain tokens to all chains via the ITS Hub:
     * - Deploy new Interchain token on local chain via the factory with an initial supply
     * - Deploy new Interchain token to each remote chain via the factory
     * - Transfer token via native method on the token
     * - Transfer tokens via ITS between chains after deployment
     */
    describe('New Interchain token via ITS Hub', () => {
        let token;
        let tokenId;
        let executable;
        const salt = getRandomBytes32();
        const gasValues = [1234, 5678];
        const tokenCap = 1e9;

        // Use a separate set of chains for this test, to avoid conflicting other tests
        const otherChains = ['hub chain 1', 'hub chain 2'];

        before(async () => {
            tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);

            // Deploy token first to get address
            await tokenFactory.deployInterchainToken(salt, name, symbol, decimals, 0, wallet.address);
            const tokenManagerAddress = await service.tokenManagerAddress(tokenId);
            const tokenManager = await getContractAt('TokenManager', tokenManagerAddress, wallet);
            const tokenAddress = await tokenManager.tokenAddress();
            token = await getContractAt('IERC20Named', tokenAddress, wallet);

            executable = await deployContract(wallet, 'TestInterchainExecutable', [service.address]);

            // Route via ITS Hub for the following chain
            for (const otherChain of otherChains) {
                await expect(service.setTrustedChain(otherChain)).to.emit(service, 'TrustedChainSet').withArgs(otherChain);
            }
        });

        it('Should register the token and initiate its deployment on other chains', async () => {
            const totalMint = tokenCap;
            const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, token.address]);

            // Deploy a new Interchain token on the local chain.
            // The initial mint occurs on the factory contract, so it can be moved to other chains within the same multicall.
            let tx = await tokenFactory.populateTransaction.deployInterchainToken(salt, name, symbol, decimals, totalMint, wallet.address);
            const calls = [tx.data];
            let value = 0;

            // Deploy a linked Interchain token to remote chains.
            for (const i in otherChains) {
                tx = await tokenFactory.populateTransaction[DEPLOY_REMOTE_INTERCHAIN_TOKEN](salt, otherChains[i], gasValues[i]);
                calls.push(tx.data);
                value += gasValues[i];
            }

            const payloads = otherChains.map((chain) =>
                encodeSendHubMessage(chain, encodeDeployInterchainTokenMessage(tokenId, name, symbol, decimals, '0x')),
            );
            const expectedTokenManagerAddress = await service.tokenManagerAddress(tokenId);

            const multicall = await tokenFactory.multicall(calls, { value });
            await expect(multicall)
                .to.emit(service, 'InterchainTokenDeployed')
                .withArgs(tokenId, expectNonZeroAddress, tokenFactory.address, name, symbol, decimals)
                .and.to.emit(service, 'TokenManagerDeployed')
                .withArgs(
                    tokenId,
                    expectedTokenManagerAddress,
                    NATIVE_INTERCHAIN_TOKEN,
                    validateTokenManagerParams('NATIVE_INTERCHAIN_TOKEN', '0x', name, symbol, decimals),
                )
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[0])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                .and.to.emit(service, 'InterchainTokenDeploymentStarted')
                .withArgs(tokenId, name, symbol, decimals, '0x', otherChains[1])
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload);

            expect(await token.balanceOf(wallet.address)).to.equal(totalMint);

            expect(await service.deployedTokenManager(tokenId)).to.equal(expectedTokenManagerAddress);
        });

        describe('Interchain transfer', () => {
            const amount = 1234;
            const destAddress = '0x1234';
            const destChain = otherChains[0];
            const gasValue = 6789;

            it('Should send some tokens to another chain via the token', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(tokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );

                await expect(token.interchainTransfer(destChain, destAddress, amount, '0x', { value: gasValue }))
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });

            it('Should send some tokens to another chain via ITS', async () => {
                const { payload, payloadHash } = encodeSendHubMessage(
                    destChain,
                    encodeInterchainTransferMessage(tokenId, arrayify(wallet.address), destAddress, amount, '0x'),
                );

                await expect(
                    service[INTERCHAIN_TRANSFER](tokenId, destChain, destAddress, amount, {
                        value: gasValue * 10 ** 10,
                    }),
                )
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloadHash, gasValue, wallet.address)
                    .to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, destChain, destAddress, amount, HashZero);
            });

            it('Should send some tokens to multiple chains via ITS', async () => {
                const calls = [];
                const destAddress = arrayify(wallet.address);
                let value = 0;

                for (const i in otherChains) {
                    const tx = await service.populateTransaction[INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE](
                        tokenId,
                        otherChains[i],
                        destAddress,
                        amount,
                        '0x',
                        gasValues[i],
                    );
                    calls.push(tx.data);
                    value += gasValues[i];
                }

                const payloads = otherChains.map((chain) =>
                    encodeSendHubMessage(chain, encodeInterchainTransferMessage(tokenId, wallet.address, destAddress, amount, '0x')),
                );

                const multicall = await service.multicall(calls, { value });
                await expect(multicall)
                    .to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, payloads[0].payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[0].payloadHash, gasValues[0], wallet.address)
                    .and.to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, otherChains[0], destAddress, amount, HashZero)
                    .and.to.emit(token, 'Transfer')
                    .withArgs(wallet.address, AddressZero, amount)
                    .and.to.emit(gateway, 'ContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, payloads[1].payload)
                    .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                    .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, payloads[1].payloadHash, gasValues[1], wallet.address)
                    .and.to.emit(service, 'InterchainTransfer')
                    .withArgs(tokenId, wallet.address, otherChains[1], destAddress, amount, HashZero);
            });
        });

        it('Should execute an application with interchain transfer via ITS Hub', async () => {
            const sourceChain = otherChains[0];
            const destChain = otherChains[1];
            const sourceAddress = arrayify(wallet.address);
            const amount = 1234;
            const gasValue = 6789; // Set this to the gas quote for the interchain call in production

            const message = 'Hello World!';
            const data = defaultAbiCoder.encode(['address', 'string'], [wallet.address, message]);
            const metadataVersion = 0;
            const metadata = solidityPack(['uint32', 'bytes'], [metadataVersion, data]);
            const sendMessage = encodeInterchainTransferMessage(tokenId, sourceAddress, executable.address, amount, data);
            const sendPayload = encodeSendHubMessage(destChain, sendMessage);
            const receiveMessage = encodeInterchainTransferMessage(tokenId, sourceAddress, executable.address, amount, data);
            const receivePayload = encodeReceiveHubMessage(sourceChain, receiveMessage);
            const commandId = getRandomBytes32();

            // Initiate the contract call with transfer
            await expect(
                service[INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE](
                    tokenId,
                    destChain,
                    executable.address,
                    amount,
                    metadata,
                    gasValue,
                    { value: gasValue },
                ),
            )
                .and.to.emit(token, 'Transfer')
                .withArgs(wallet.address, AddressZero, amount)
                .and.to.emit(gateway, 'ContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, sendPayload.payloadHash, sendPayload.payload)
                .and.to.emit(gasService, 'NativeGasPaidForContractCall')
                .withArgs(service.address, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, sendPayload.payloadHash, gasValue, wallet.address)
                .to.emit(service, 'InterchainTransfer')
                .withArgs(tokenId, wallet.address, destChain, executable.address.toLowerCase(), amount, keccak256(data));

            await approveContractCall(
                gateway,
                ITS_HUB_CHAIN,
                ITS_HUB_ADDRESS,
                service.address,
                receivePayload.payload,
                getRandomBytes32(),
                0,
                commandId,
            );

            // Execute the contract call on destination with transfer
            await expect(service.execute(commandId, ITS_HUB_CHAIN, ITS_HUB_ADDRESS, receivePayload.payload))
                .to.emit(service, 'InterchainTransferReceived')
                .withArgs(commandId, tokenId, sourceChain, sourceAddress, executable.address, amount, keccak256(data))
                .and.to.emit(token, 'Transfer')
                .withArgs(AddressZero, executable.address, amount)
                .and.to.emit(token, 'Transfer')
                .withArgs(executable.address, wallet.address, amount)
                .and.to.emit(executable, 'MessageReceived')
                .withArgs(commandId, sourceChain, sourceAddress, wallet.address, message, tokenId, amount);
        });
    });
});
