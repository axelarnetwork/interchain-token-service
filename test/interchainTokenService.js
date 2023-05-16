'use strict';

require('dotenv').config();

const { networks, relay, logger, stopAll } = require('@axelar-network/axelar-local-dev');
const {
    ethers: {
        Contract,
        Wallet,
        constants: { AddressZero },
        utils: { keccak256, defaultAbiCoder },
    },
} = require('hardhat');
const { expect } = require('chai');
const Token = require('../artifacts/contracts/interfaces/IInterchainToken.sol/IInterchainToken.json');
const LinkerRouter = require('../artifacts/contracts/linkerRouter/LinkerRouter.sol/LinkerRouter.json');
const ExpressCallHandler = require('../artifacts/contracts/interfaces/IExpressCallHandler.sol/IExpressCallHandler.json');
const TestToken = require('../artifacts/contracts/test/InterchainTokenTest.sol/InterchainTokenTest.json');
const { setupLocal, prepareChain, deployToken, getTokenData, relayRevert, relayAndFulfill } = require('../scripts/utils.js');
const { deployCreate3Contract } = require('@axelar-network/axelar-gmp-sdk-solidity');

logger.log = (args) => {};

const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
const notOwnerKey = keccak256(defaultAbiCoder.encode(['string'], ['not-owner']));
let chains;

describe('TokenService', () => {
    before(async () => {
        const deployerAddress = new Wallet(deployerKey).address;
        const notOwnerAddress = new Wallet(notOwnerKey).address;
        const toFund = [deployerAddress, notOwnerAddress];
        chains = await setupLocal(toFund, 3);

        for (const chain of chains) {
            await prepareChain(chain, deployerKey, notOwnerKey);
        }
    });

    after(async () => {
        await stopAll();
    });

    describe('Deployments and Registrations', () => {
        let token;
        const name = 'Test Token';
        const symbol = 'TT';
        const decimals = 13;
        const key = `tokenServiceKey`;
        let wallet, chain, remoteChain, tokenId;
        let salt = keccak256(defaultAbiCoder.encode(['string'], [key]));

        before(async () => {
            chain = chains[0];
            wallet = chain.ownerWallet;
            remoteChain = chains[1];
        });

        it('Should be able to deploy a native interchain token', async () => {
            const [tokenAddress, tokenId] = await getTokenData(chain, wallet.address, salt, true);
            await expect(chain.service.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], []))
                .to.emit(chain.service, 'TokenDeployed')
                .withArgs(tokenAddress, name, symbol, decimals, wallet.address)
                .and.to.emit(chain.service, 'TokenRegistered')
                .withArgs(tokenId, tokenAddress, true, false, false);
            token = new Contract(tokenAddress, Token.abi, chain.provider);
            expect(await token.name()).to.equal(name);
            expect(await token.symbol()).to.equal(symbol);
            expect(await token.decimals()).to.equal(decimals);
            expect(await token.owner()).to.equal(wallet.address);
            expect(await chain.service.getTokenId(tokenAddress)).to.equal(tokenId);
            expect(await chain.service.getTokenAddress(tokenId)).to.equal(tokenAddress);
        });

        it('Should not be able to deploy a native interchain token with the same sender and salt', async () => {
            await expect(chain.service.deployInterchainToken(name, symbol, decimals, wallet.address, salt, [], [])).to.be.reverted;
        });

        it('Should not be able to register an origin token that does not exist', async () => {
            const [tokenAddress] = await getTokenData(chain, wallet.address, salt, false);

            await expect(chain.service.registerOriginToken(tokenAddress)).to.be.reverted;
        });

        it('Should be able to register an origin token', async () => {
            [token, tokenId] = await deployToken(chain, name, symbol, decimals, wallet.address, salt);

            expect(await token.name()).to.equal(name);
            expect(await token.symbol()).to.equal(symbol);
            expect(await token.decimals()).to.equal(decimals);
            expect(await token.owner()).to.equal(wallet.address);
            await expect(chain.service.registerOriginToken(token.address))
                .to.emit(chain.service, 'TokenRegistered')
                .withArgs(tokenId, token.address, true, false, false);

            expect(await chain.service.getTokenId(token.address)).to.equal(tokenId);
            expect(await chain.service.getTokenAddress(tokenId)).to.equal(token.address);
        });

        it('Should not be able to register an origin token that has already been registered', async () => {
            await expect(chain.service.registerOriginToken(token.address)).to.be.reverted;
        });

        it('Should not be able to register an origin token and deploy remote tokens if that token has already been registered', async () => {
            await expect(chain.service.registerOriginTokenAndDeployRemoteTokens(token.address, [], [])).to.be.reverted;
        });

        it('Should be able to deploy a remote token for the origin token', async () => {
            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];
            await expect(chain.service.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }))
                .to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[0], gasValues[0])
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[1], gasValues[1]);
            await relay();

            for (const i of [1, 2]) {
                const remoteTokenAddress = await chains[i].service.getTokenAddress(tokenId);
                expect(remoteTokenAddress).to.not.equal(AddressZero);
                expect(await chains[i].service.getTokenId(remoteTokenAddress)).to.equal(tokenId);
            }
        });

        it('Should not be able to register an origin token if that token is remote', async () => {
            const tokenAddress = await remoteChain.service.getTokenAddress(tokenId);
            await expect(remoteChain.service.registerOriginToken(tokenAddress, [], [])).to.be.reverted;
        });

        it('Should not be able to register an origin token and deploy remote tokens if that token is remote', async () => {
            const tokenAddress = await remoteChain.service.getTokenAddress(tokenId);
            await expect(remoteChain.service.registerOriginTokenAndDeployRemoteTokens(tokenAddress, [], [])).to.be.reverted;
        });

        it('Should not be able to deploy a remote token for the origin token again', async () => {
            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];
            expect(await relayRevert(chain.service.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }), false, 2)).to
                .be.true;
        });

        it('Should be able to deploy a remote token for the origin token deployed at the service', async () => {
            [, tokenId] = await getTokenData(chain, wallet.address, salt, true);
            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];
            await expect(chain.service.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }))
                .to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[0], gasValues[0])
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[1], gasValues[1]);

            await relay();

            for (const i of [1, 2]) {
                const remoteTokenAddress = await chains[i].service.getTokenAddress(tokenId);
                expect(remoteTokenAddress).to.not.equal(AddressZero);
                expect(await chains[i].service.getTokenId(remoteTokenAddress)).to.equal(tokenId);
            }
        });

        it('Should not be able to deploy a remote token for the origin token again', async () => {
            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];
            expect(await relayRevert(chain.service.deployRemoteTokens(tokenId, destinationChains, gasValues, { value: 2e7 }), false, 2)).to
                .be.true;
        });

        it('Should be able to register a token and deploy remote tokens in one go', async () => {
            salt = keccak256('0x1234567890');
            const [token, tokenId] = await deployToken(chain, name, symbol, decimals, wallet.address, salt);

            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];

            await expect(
                chain.service.registerOriginTokenAndDeployRemoteTokens(token.address, destinationChains, gasValues, { value: 2e7 }),
            )
                .to.emit(chain.service, 'TokenRegistered')
                .withArgs(tokenId, token.address, true, false, false)
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[0], gasValues[0])
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[1], gasValues[1]);

            expect(await chain.service.getTokenId(token.address)).to.equal(tokenId);
            expect(await chain.service.getTokenAddress(tokenId)).to.equal(token.address);

            await relay();

            for (const i of [1, 2]) {
                const tokenService = chains[i].service;
                const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
                expect(remoteTokenAddress).to.not.equal(AddressZero);
                expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
            }
        });

        it('Should be able to deploy an interchain token and deploy remote tokens in one go', async () => {
            const [tokenAddress, tokenId] = await getTokenData(chain, wallet.address, salt, true);

            const destinationChains = [chains[1].name, chains[2].name];
            const gasValues = [1e7, 1e7];

            await expect(
                chain.service.deployInterchainToken(name, symbol, decimals, wallet.address, salt, destinationChains, gasValues, {
                    value: 2e7,
                }),
            )
                .to.emit(chain.service, 'TokenDeployed')
                .withArgs(tokenAddress, name, symbol, decimals, wallet.address)
                .and.to.emit(chain.service, 'TokenRegistered')
                .withArgs(tokenId, tokenAddress, true, false, false)
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[0], gasValues[0])
                .and.to.emit(chain.service, 'RemoteTokenRegisterInitialized')
                .withArgs(tokenId, destinationChains[1], gasValues[1]);

            expect(await chain.service.getTokenId(tokenAddress)).to.equal(tokenId);
            expect(await chain.service.getTokenAddress(tokenId)).to.equal(tokenAddress);

            await relay();

            for (const i of [1, 2]) {
                const tokenService = chains[i].service;
                const remoteTokenAddress = await tokenService.getTokenAddress(tokenId);
                expect(remoteTokenAddress).to.equal(tokenAddress);
                expect(await tokenService.getTokenId(remoteTokenAddress)).to.equal(tokenId);
            }
        });

        describe('Gateway Tokens', () => {
            const gatewayTokenName = 'Gateway Token';
            const gatewayTokenSymbol = 'GT';
            const gatewayTokenDecimals = 18;
            const gatewayTokenSalt = keccak256(defaultAbiCoder.encode(['string'], ['gatewayToken']));
            let tokenId, gatewayTokenAddress, remoteGatewayTokenAddress, chain;
            before(async () => {
                chain = chains[0];
                let token;
                [token, tokenId] = await deployToken(
                    chain,
                    gatewayTokenName,
                    gatewayTokenSymbol,
                    gatewayTokenDecimals,
                    chain.ownerWallet.address,
                    gatewayTokenSalt,
                );

                await networks[0].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0, token.address);
                expect(await networks[0].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(token.address);
                const remoteGatewayToken = await networks[1].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0);
                gatewayTokenAddress = token.address;
                remoteGatewayTokenAddress = remoteGatewayToken.address;
                expect(await networks[1].gateway.tokenAddresses(gatewayTokenSymbol)).to.not.equal(AddressZero);
                expect(await networks[2].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(AddressZero);
            });

            it('Should not be able to register gateway tokens as not the owner', async () => {
                await expect(chain.service.connect(chain.otherWallet).registerOriginGatewayToken(gatewayTokenSymbol)).to.be.reverted;
                await expect(
                    chain.service.connect(chain.otherWallet).registerRemoteGatewayToken(gatewayTokenSymbol, keccak256('0x'), 'Anything'),
                ).to.be.reverted;
            });

            it('Should not be able to register gateway tokens that are not gateway tokens', async () => {
                const newSymbol = 'NS';

                await expect(chain.service.registerOriginGatewayToken(newSymbol)).to.be.reverted;
                await expect(chain.service.registerRemoteGatewayToken(newSymbol, keccak256('0x'), 'Anything')).to.be.reverted;
            });

            it('Should be able to register the origin token', async () => {
                await chain.service.registerOriginGatewayToken(gatewayTokenSymbol);
                expect(await chain.service.getTokenAddress(tokenId)).to.equal(gatewayTokenAddress);
                expect(await chain.service.getTokenId(gatewayTokenAddress)).to.equal(tokenId);

                expect(await chain.service.isOriginToken(tokenId)).to.be.true;
                expect(await chain.service.isGatewayToken(tokenId)).to.equal(true);
                expect(await chain.service.isRemoteGatewayToken(tokenId)).to.false;
                expect(await chain.service.getGatewayTokenSymbol(tokenId)).to.equal(gatewayTokenSymbol);
            });

            it('Should be able to register the remote token', async () => {
                const tokenService = chains[1].service;
                await tokenService.registerRemoteGatewayToken(gatewayTokenSymbol, tokenId, chains[0].name);
                expect(await tokenService.getTokenAddress(tokenId)).to.equal(remoteGatewayTokenAddress);
                expect(await tokenService.getTokenId(remoteGatewayTokenAddress)).to.equal(tokenId);

                expect(await tokenService.isOriginToken(tokenId)).to.equal(false);
                expect(await tokenService.isGatewayToken(tokenId)).to.equal(true);
                expect(await tokenService.isRemoteGatewayToken(tokenId)).to.equal(false);
                expect(await tokenService.getGatewayTokenSymbol(tokenId)).to.equal(gatewayTokenSymbol);
            });

            it('Should not be able to deploy the gateway token to a the chain that has the token', async () => {
                expect(await relayRevert(chain.service.deployRemoteTokens(tokenId, [chains[1].name], [1e7], { value: 1e7 }))).to.be.true;
            });

            it('Should be able to deploy the gateway token to a third chain', async () => {
                await chain.service.deployRemoteTokens(tokenId, [chains[2].name], [1e7], { value: 1e7 });

                await relay();

                const remoteTokenService = chains[2].service;
                expect(await remoteTokenService.getTokenAddress(tokenId)).to.not.equal(AddressZero);

                expect(await remoteTokenService.isOriginToken(tokenId)).to.equal(false);
                expect(await remoteTokenService.isGatewayToken(tokenId)).to.equal(false);
                expect(await remoteTokenService.isRemoteGatewayToken(tokenId)).to.equal(true);
            });
        });
    });

    const titles = [
        'for a token deployed at the service',
        'for a custon origin token with service remote deployments',
        'for custom tokens everywhere',
        'for a gateway token',
    ];
    const sends = 2;
    const amount = 1234;
    const prepares = [
        async () => {
            const chain = chains[0];
            const [token, tokenId] = await deployToken(chain, 'Name', 'Symbol', 18, chain.ownerWallet.address, keccak256('0x123487'), {
                fromService: true,
                remoteDeployments: [chains[1].name, chains[2].name],
            });
            await token.mint(chain.ownerWallet.address, amount * sends);
            return tokenId;
        },
        async () => {
            const chain = chains[0];
            const [token, tokenId] = await deployToken(chain, 'Name', 'Symbol', 18, chain.ownerWallet.address, keccak256('0x123487'), {
                fromService: false,
                register: true,
                remoteDeployments: [chains[1].name, chains[2].name],
            });
            await token.mint(chain.ownerWallet.address, amount * sends);

            return tokenId;
        },
        async () => {
            let tokenId;

            for (let i = 0; i < 3; i++) {
                const chain = chains[i];
                const token = await deployCreate3Contract(chain.create3Deployer, chain.ownerWallet, TestToken, 'customToken', [
                    chain.service.address,
                    'Name',
                    'Symbol',
                    18,
                    chain.ownerWallet.address,
                    i === 0 ? amount * sends : 0,
                ]);

                if (i === 0) tokenId = await chain.service.getTokenId(token.address);
            }

            return tokenId;
        },
        async () => {
            const gatewayTokenName = 'Gateway Token Name';
            const gatewayTokenSymbol = 'GTN';
            const gatewayTokenDecimals = 18;
            const chain = chains[0];
            const [token] = await deployToken(
                chain,
                gatewayTokenName,
                gatewayTokenSymbol,
                gatewayTokenDecimals,
                chain.ownerWallet.address,
                keccak256('0x12348779'),
                {
                    fromService: false,
                    register: false,
                },
            );

            await networks[0].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0, token.address);
            await networks[1].deployToken(gatewayTokenName, gatewayTokenSymbol, gatewayTokenDecimals, 0);
            expect(await networks[0].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(token.address);
            expect(await networks[1].gateway.tokenAddresses(gatewayTokenSymbol)).to.not.equal(AddressZero);
            expect(await networks[2].gateway.tokenAddresses(gatewayTokenSymbol)).to.equal(AddressZero);

            await chain.service.registerOriginGatewayToken(gatewayTokenSymbol);
            const tokenId = await chain.service.getTokenId(token.address);
            await chains[1].service.registerRemoteGatewayToken(gatewayTokenSymbol, tokenId, chain.name);

            await chain.service.deployRemoteTokens(tokenId, [chains[2].name], [1e7], { value: 1e7 });
            await token.mint(chain.ownerWallet.address, amount * sends);

            for (let i = 0; i < 3; i++) {
                const chain = chains[i];
                const linkerRouter = new Contract(await chain.service.linkerRouter(), LinkerRouter.abi, chain.ownerWallet);

                const names = [];

                for (let j = 0; j < 2; j++) {
                    if (i === j) continue;
                    names.push(chains[j].name);
                }

                await linkerRouter.addGatewaySupportedChains(names);

                for (let j = 0; j < 3; j++) {
                    if (i === j) continue;
                    expect(await linkerRouter.supportedByGateway(chains[j].name)).to.equal(j < 2);
                }
            }

            return tokenId;
        },
    ];

    for (let i = 0; i < titles.length; i++) {
        describe(`Send Token ${titles[i]}`, () => {
            let tokenId, origin, dest, originToken, destToken;
            before(async () => {
                tokenId = await prepares[i]();
            });

            for (let incr = 1; incr <= 2; incr++) {
                for (let j = 0; j < 3 * incr; j += incr) {
                    describe(`Sending token from ${j % 3} to ${(j + incr) % 3}`, () => {
                        before(async () => {
                            origin = chains[j % 3];
                            dest = chains[(j + incr) % 3];
                            const originTokenAddress = await origin.service.getTokenAddress(tokenId);
                            originToken = new Contract(originTokenAddress, Token.abi, origin.ownerWallet);
                            const destTokenAddress = await dest.service.getTokenAddress(tokenId);
                            destToken = new Contract(destTokenAddress, Token.abi, dest.ownerWallet);
                            expect(await originToken.balanceOf(origin.ownerWallet.address)).to.equal(amount * sends);
                            expect(await destToken.balanceOf(origin.ownerWallet.address)).to.equal(0);
                        });

                        it('Should not be able to send token without approval', async () => {
                            await expect(origin.service.sendToken(tokenId, dest.name, dest.ownerWallet.address, amount, { value: 1e6 })).to
                                .be.reverted;
                        });

                        it('Should be able to send some token', async () => {
                            await originToken.approve(origin.service.address, amount);

                            const blockNumber = await origin.provider.getBlockNumber();
                            const sendHash = keccak256(
                                defaultAbiCoder.encode(
                                    ['uint256', 'bytes32', 'address'],
                                    [blockNumber + 1, tokenId, origin.ownerWallet.address],
                                ),
                            );

                            await expect(origin.service.sendToken(tokenId, dest.name, dest.ownerWallet.address, amount, { value: 1e6 }))
                                .to.emit(origin.service, 'Sending')
                                .withArgs(dest.name, dest.ownerWallet.address.toLowerCase(), amount, sendHash);

                            expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount * (sends - 1));

                            await relay();

                            await relayAndFulfill(dest.ownerWallet);

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
                        });

                        it('Should be able to express send some token over', async () => {
                            await originToken.approve(origin.service.address, amount);

                            const blockNumber = await origin.provider.getBlockNumber();
                            const sendHash = keccak256(
                                defaultAbiCoder.encode(
                                    ['uint256', 'bytes32', 'address'],
                                    [blockNumber + 1, tokenId, origin.ownerWallet.address],
                                ),
                            );

                            await expect(origin.service.sendToken(tokenId, dest.name, dest.otherWallet.address, amount, { value: 1e6 }))
                                .to.emit(origin.service, 'Sending')
                                .withArgs(dest.name, dest.otherWallet.address.toLowerCase(), amount, sendHash);

                            expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount * (sends - 2));

                            await destToken.approve(dest.service.address, amount);

                            const expressCallHandler = new Contract(
                                await dest.service.expressCallHandler(),
                                ExpressCallHandler.abi,
                                dest.provider,
                            );

                            await expect(dest.service.expressExecute(tokenId, dest.otherWallet.address, amount, sendHash))
                                .to.emit(expressCallHandler, 'ExpressExecuted')
                                .withArgs(tokenId, dest.otherWallet.address, amount, sendHash, origin.ownerWallet.address);

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(0);
                            expect(Number(await destToken.balanceOf(dest.otherWallet.address))).to.equal(amount);

                            await relay();

                            await relayAndFulfill(dest.ownerWallet);

                            const filter = expressCallHandler.filters.ExpressExecutionFulfilled(
                                tokenId,
                                dest.otherWallet.address,
                                null,
                                sendHash,
                                null,
                            );
                            const logs = await expressCallHandler.queryFilter(filter);
                            expect(logs.length).to.equal(1);
                            const args = logs[0].args;
                            expect(args.amount).to.equal(amount);
                            expect(args.expressCaller).to.equal(dest.ownerWallet.address);

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
                            expect(Number(await destToken.balanceOf(dest.otherWallet.address))).to.equal(amount);

                            await destToken.connect(dest.otherWallet).transfer(dest.ownerWallet.address, amount);
                        });

                        it('Should not be able to send some token to another chain with insufficient balance', async () => {
                            await originToken.approve(origin.service.address, amount);

                            await expect(origin.service.sendToken(tokenId, dest.name, dest.ownerWallet.address, amount, { value: 1e6 })).to
                                .be.reverted;

                            await originToken.approve(origin.service.address, 0);
                        });
                    });
                }
            }

            for (let incr = 1; incr <= 2; incr++) {
                for (let j = 0; j < 3 * incr; j += incr) {
                    describe(`Sending token with data from ${j % 3} to ${(j + incr) % 3}`, () => {
                        const val = `from ${j % 3} to ${(j + incr) % 3}`;
                        let payload;
                        before(async () => {
                            origin = chains[j % 3];
                            dest = chains[(j + incr) % 3];
                            const originTokenAddress = await origin.service.getTokenAddress(tokenId);
                            originToken = new Contract(originTokenAddress, Token.abi, origin.ownerWallet);
                            const destTokenAddress = await dest.service.getTokenAddress(tokenId);
                            destToken = new Contract(destTokenAddress, Token.abi, dest.ownerWallet);
                            expect(await originToken.balanceOf(origin.ownerWallet.address)).to.equal(amount * sends);
                            expect(await destToken.balanceOf(origin.ownerWallet.address)).to.equal(0);
                            payload = defaultAbiCoder.encode(['address', 'string'], [dest.ownerWallet.address, val]);
                        });

                        it('Should not be able to send token without approval', async () => {
                            await expect(
                                origin.service.callContractWithInterchainToken(
                                    tokenId,
                                    dest.name,
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    { value: 1e6 },
                                ),
                            ).to.be.reverted;
                        });

                        it('Should be able to send some token', async () => {
                            await originToken.approve(origin.service.address, amount);

                            const blockNumber = await origin.provider.getBlockNumber();
                            const sendHash = keccak256(
                                defaultAbiCoder.encode(
                                    ['uint256', 'bytes32', 'address'],
                                    [blockNumber + 1, tokenId, origin.ownerWallet.address],
                                ),
                            );

                            await expect(
                                origin.service.callContractWithInterchainToken(
                                    tokenId,
                                    dest.name,
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    { value: 1e6 },
                                ),
                            )
                                .to.emit(origin.service, 'SendingWithData')
                                .withArgs(
                                    origin.ownerWallet.address,
                                    dest.name,
                                    dest.executable.address.toLowerCase(),
                                    amount,
                                    payload,
                                    sendHash,
                                );

                            expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount * (sends - 1));

                            await relay();

                            await relayAndFulfill(dest.ownerWallet);

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
                        });

                        it('Should be able to express send some token over', async () => {
                            payload = defaultAbiCoder.encode(['address', 'string'], [dest.otherWallet.address, val]);
                            await originToken.approve(origin.service.address, amount);

                            const blockNumber = await origin.provider.getBlockNumber();
                            const sendHash = keccak256(
                                defaultAbiCoder.encode(
                                    ['uint256', 'bytes32', 'address'],
                                    [blockNumber + 1, tokenId, origin.ownerWallet.address],
                                ),
                            );

                            await expect(
                                origin.service.callContractWithInterchainToken(
                                    tokenId,
                                    dest.name,
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    { value: 1e6 },
                                ),
                            )
                                .to.emit(origin.service, 'SendingWithData')
                                .withArgs(
                                    origin.ownerWallet.address,
                                    dest.name,
                                    dest.executable.address.toLowerCase(),
                                    amount,
                                    payload,
                                    sendHash,
                                );

                            expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount * (sends - 2));

                            await destToken.approve(dest.service.address, amount);

                            const expressCallHandler = new Contract(
                                await dest.service.expressCallHandler(),
                                ExpressCallHandler.abi,
                                dest.provider,
                            );

                            await expect(
                                dest.service.expressExecuteWithToken(
                                    tokenId,
                                    origin.name,
                                    origin.ownerWallet.address,
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    sendHash,
                                ),
                            )
                                .to.emit(expressCallHandler, 'ExpressExecutedWithData')
                                .withArgs(
                                    tokenId,
                                    origin.name,
                                    origin.ownerWallet.address.toLowerCase(),
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    sendHash,
                                    dest.ownerWallet.address,
                                );

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(0);
                            expect(Number(await destToken.balanceOf(dest.otherWallet.address))).to.equal(amount);

                            await relay();

                            await relayAndFulfill(dest.ownerWallet);

                            const filter = expressCallHandler.filters.ExpressExecutionWithDataFulfilled(
                                tokenId,
                                null,
                                null,
                                dest.executable.address,
                                null,
                                null,
                                sendHash,
                                null,
                            );
                            const logs = await expressCallHandler.queryFilter(filter);
                            expect(logs.length).to.equal(1);
                            const args = logs[0].args;
                            expect(args.sourceChain).to.equal(origin.name);
                            expect(args.sourceAddress).to.equal(origin.ownerWallet.address.toLowerCase());
                            expect(args.amount).to.equal(amount);
                            expect(args.data).to.equal(payload);
                            expect(args.expressCaller).to.equal(dest.ownerWallet.address);

                            expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
                            expect(Number(await destToken.balanceOf(dest.otherWallet.address))).to.equal(amount);

                            await destToken.connect(dest.otherWallet).transfer(dest.ownerWallet.address, amount);
                        });

                        it('Should not be able to send some token to another chain with insufficient balance', async () => {
                            await originToken.approve(origin.service.address, amount);

                            await expect(
                                origin.service.callContractWithInterchainToken(
                                    tokenId,
                                    dest.name,
                                    dest.executable.address,
                                    amount,
                                    payload,
                                    { value: 1e6 },
                                ),
                            ).to.be.reverted;

                            await originToken.approve(origin.service.address, 0);
                        });
                    });
                }
            }
        });
    }

    describe('Mint Limits', () => {
        const salt = keccak256('0x96858473');
        const mintLimit = 125;
        let tokenId, originToken, destToken, origin, dest;
        before(async () => {
            origin = chains[0];
            dest = chains[1];
            [originToken, tokenId] = await deployToken(origin, 'Name', 'Symbol', 18, origin.ownerWallet.address, salt, {
                fromService: true,
                remoteDeployments: [dest.name],
            });
            await originToken.mint(origin.ownerWallet.address, mintLimit * 3);

            const destTokenAddress = await dest.service.getTokenAddress(tokenId);
            destToken = new Contract(destTokenAddress, Token.abi, dest.ownerWallet);
        });

        it('Should be able to set a mint limit for a new token', async () => {
            expect(await origin.service.getTokenMintLimit(tokenId)).to.equal(0);

            await origin.service.setTokenMintLimit(tokenId, mintLimit);

            expect(await origin.service.getTokenMintLimit(tokenId)).to.equal(mintLimit);

            expect(await dest.service.getTokenMintLimit(tokenId)).to.equal(0);

            await dest.service.setTokenMintLimit(tokenId, mintLimit * 2);

            expect(await dest.service.getTokenMintLimit(tokenId)).to.equal(mintLimit * 2);
        });

        it('Should be able to sent up to the mint limit but no more', async () => {
            await originToken.approve(origin.service.address, mintLimit * 3);

            await origin.service.sendToken(tokenId, dest.name, dest.ownerWallet.address, mintLimit * 2, { value: 1e6 });

            await relay();

            expect(await destToken.balanceOf(dest.ownerWallet.address)).to.equal(mintLimit * 2);

            expect(await relayRevert(origin.service.sendToken(tokenId, dest.name, dest.ownerWallet.address, mintLimit, { value: 1e6 }))).to
                .be.true;

            await destToken.approve(origin.service.address, mintLimit * 2);

            await dest.service.sendToken(tokenId, origin.name, origin.ownerWallet.address, mintLimit, { value: 1e6 });

            await relay();

            expect(await originToken.balanceOf(origin.ownerWallet.address)).to.equal(mintLimit);

            expect(await relayRevert(dest.service.sendToken(tokenId, origin.name, origin.ownerWallet.address, mintLimit, { value: 1e6 })))
                .to.be.true;
        });
    });
});
