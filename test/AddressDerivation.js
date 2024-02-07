'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const {
    constants: { AddressZero },
    utils: { defaultAbiCoder },
} = ethers;
const { deployAll } = require('../scripts/deploy');
const { approveContractCall } = require('../scripts/utils');
const { getRandomBytes32, getSaltFromKey, isHardhat, getContractJSON } = require('./utils');
const { create3DeployContract } = require('@axelar-network/axelar-gmp-sdk-solidity');
const Token = getContractJSON('TestInterchainTokenStandard');
const MINT_BURN = 0;
const MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 1;

if (isHardhat) {
    describe('Token Address Derivation [ @skip-on-coverage ]', () => {
        let wallet;
        let service;
        let gateway;
        let create3Deployer;
        let tokenFactory;
        let token;
        let sourceAddress;

        const destinationChain = 'destination chain';
        const sourceChain = 'source chain';
        const tokenName = 'Token Name';
        const tokenSymbol = 'TN';
        const tokenDecimals = 18;

        before(async () => {
            const wallets = await ethers.getSigners();
            wallet = wallets[0];

            ({ service, gateway, tokenFactory, create3Deployer } = await deployAll(wallet, 'Test', [sourceChain, destinationChain]));
            token = await create3DeployContract(create3Deployer.address, wallet, Token, 'Test', [
                tokenName,
                tokenSymbol,
                tokenDecimals,
                service.address,
                getRandomBytes32(),
            ]);

            sourceAddress = service.address;
        });

        describe('Interchain Token Service Deployments', () => {
            it('Should derive the correct token address for interchain token deployment on source chain', async () => {
                const salt = getSaltFromKey('deployInterchainToken');
                const tokenId = await service.interchainTokenId(wallet.address, salt);

                const expectedTokenAddress = '0x2b7c2c1f7297BB9a573Fb970D086F0d113722Ceb';
                const expectedTokenManagerAddress = '0x1248d7831b5B231147bfbDb5e2b29B0110EeC9C8';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, expectedTokenAddress]);

                await expect(service.deployInterchainToken(salt, '', tokenName, tokenSymbol, tokenDecimals, wallet.address, 0))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, wallet.address, tokenName, tokenSymbol, tokenDecimals)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });

            it('Should derive the correct token address for remote interchain token deployment', async () => {
                const salt = getSaltFromKey('deployRemoteInterchainToken');
                const tokenId = await service.interchainTokenId(wallet.address, salt);
                const minter = wallet.address;
                const operator = wallet.address;

                const expectedTokenAddress = '0xDeB68Eb8F7D583140ce9158068f697F7B3a54Fb9';
                const expectedTokenManagerAddress = '0x3B058fE7Ed045f56F0152AED1e8c5fbaE7e23C70';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, expectedTokenAddress]);
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                    [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter],
                );
                const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

                await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, minter, tokenName, tokenSymbol, tokenDecimals)
                    .and.to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });

            it('Should derive the correct token address for remote interchain token deployment with empty minter and operator', async () => {
                const salt = getSaltFromKey('deployRemoteInterchainTokenEmpty');
                const tokenId = await service.interchainTokenId(wallet.address, salt);
                const minter = '0x';
                const operator = '0x';

                const expectedTokenAddress = '0x98D4481F4c1FC0608862e573Db15d0640F2E1B14';
                const expectedTokenManagerAddress = '0x89AF99D9373722De5F29ABbF706efeD020ae3E1F';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, expectedTokenAddress]);
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                    [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter],
                );
                const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

                await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, AddressZero, tokenName, tokenSymbol, tokenDecimals)
                    .and.to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });
        });

        describe.only('Interchain Token Factory Deployments', () => {
            const initialSupply = 100;

            it('Should derive the correct token address for interchain token deployment on source chain', async () => {
                const salt = getSaltFromKey('deployInterchainToken');
                const tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);

                const expectedTokenAddress = '0xD48F12c4b65135575495C476977B893D8e817B4b';
                const expectedTokenManagerAddress = '0xcb7DEA0Aeb34A992451717C0537b5C4eA1635A54';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [tokenFactory.address, expectedTokenAddress]);

                await expect(tokenFactory.deployInterchainToken(salt, tokenName, tokenSymbol, tokenDecimals, initialSupply, wallet.address))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, tokenFactory.address, tokenName, tokenSymbol, tokenDecimals)
                    .to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
                    console.log(await service.interchainTokenAddress(tokenId), expectedTokenAddress);
                    console.log(await service.tokenManagerAddress(tokenId), expectedTokenManagerAddress);
                    console.log(tokenId);
            });

            it('Should derive the correct token address for remote interchain token deployment', async () => {
                const salt = getSaltFromKey('deployRemoteInterchainToken');
                const tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
                const minter = wallet.address;
                const operator = wallet.address;

                const expectedTokenAddress = '0x977178149Ae62EFB70fD9BBa3e9200663Bdcb13c';
                const expectedTokenManagerAddress = '0x1695DD538BeDd759BE212Ed24f809eA51dbc08D0';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, expectedTokenAddress]);
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                    [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter],
                );

                const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

                await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, minter, tokenName, tokenSymbol, tokenDecimals)
                    .and.to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });

            it('Should derive the correct token address for remote interchain token deployment with empty minter and operator', async () => {
                const salt = getSaltFromKey('deployRemoteInterchainTokenEmpty');
                const tokenId = await tokenFactory.interchainTokenId(wallet.address, salt);
                const minter = AddressZero;
                const operator = '0x';

                const expectedTokenAddress = '0x99ea4db7a1Aca4aC8d44fbbD6e2BD49960F6163a';
                const expectedTokenManagerAddress = '0x123908f4742664f68db857c6a10c846fb557AF08';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, expectedTokenAddress]);
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                    [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, '0x'],
                );

                const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

                await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, minter, tokenName, tokenSymbol, tokenDecimals)
                    .and.to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });

            it('Should derive the correct token address for remote canonical token deployment', async () => {
                const tokenId = await tokenFactory.canonicalInterchainTokenId(token.address);
                const minter = wallet.address;
                const operator = wallet.address;

                const expectedTokenAddress = '0x74305d7DBD2a9Aa2994825995504b7e97bDF4430';
                const expectedTokenManagerAddress = '0x43eb02B89a4478128Df888260254efFd75b6D2eA';

                const params = defaultAbiCoder.encode(['bytes', 'address'], [operator, expectedTokenAddress]);
                const payload = defaultAbiCoder.encode(
                    ['uint256', 'bytes32', 'string', 'string', 'uint8', 'bytes'],
                    [MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN, tokenId, tokenName, tokenSymbol, tokenDecimals, minter],
                );

                const commandId = await approveContractCall(gateway, sourceChain, sourceAddress, service.address, payload);

                await expect(service.execute(commandId, sourceChain, sourceAddress, payload))
                    .to.emit(service, 'InterchainTokenDeployed')
                    .withArgs(tokenId, expectedTokenAddress, minter, tokenName, tokenSymbol, tokenDecimals)
                    .and.to.emit(service, 'TokenManagerDeployed')
                    .withArgs(tokenId, expectedTokenManagerAddress, MINT_BURN, params);
            });
        });
    });
}
