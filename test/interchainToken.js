'use strict';

require('dotenv').config();

const { relay, logger, stopAll } = require('@axelar-network/axelar-local-dev');
const {
    ethers: {
        Contract,
        Wallet,
        utils: { keccak256, defaultAbiCoder },
    },
} = require('hardhat');
const { expect } = require('chai');
const Token = require('../artifacts/contracts/interfaces/IInterchainToken.sol/IInterchainToken.json');
const { setupLocal, prepareChain, getTokenData } = require('../scripts/utils.js');

logger.log = (args) => {};

const deployerKey = keccak256(defaultAbiCoder.encode(['string'], [process.env.PRIVATE_KEY_GENERATOR]));
const notOwnerKey = keccak256(defaultAbiCoder.encode(['string'], ['not-owner']));
let chains;

describe('Token', () => {
    const name = 'Test Token';
    const symbol = 'TT';
    const decimals = 13;
    const key = `tokenServiceKey`;
    const salt = keccak256(defaultAbiCoder.encode(['string'], [key]));
    const amount = 123456;
    let origin, dest, originToken, destToken, tokenId;

    before(async () => {
        const deployerAddress = new Wallet(deployerKey).address;
        const notOwnerAddress = new Wallet(notOwnerKey).address;
        const toFund = [deployerAddress, notOwnerAddress];
        chains = await setupLocal(toFund, 2);

        for (const chain of chains) {
            await prepareChain(chain, deployerKey, notOwnerKey);
        }

        const chain = chains[0];

        const destinationChains = [chains[1].name];
        const gasValues = [1e7];

        await chain.service.deployInterchainToken(name, symbol, decimals, chain.ownerWallet.address, salt, destinationChains, gasValues, {
            value: 1e7,
        });
        await relay();

        let originTokenAddress;
        [originTokenAddress, tokenId] = await getTokenData(chain, chain.ownerWallet.address, salt, true);
        originToken = new Contract(originTokenAddress, Token.abi, chain.ownerWallet);
        await originToken.mint(chain.ownerWallet.address, amount * 2);
    });

    after(async () => {
        await stopAll();
    });

    for (let i = 0; i < 2; i++) {
        describe(`Should send token from ${i} to ${1 - i}`, () => {
            before(async () => {
                origin = chains[i];
                dest = chains[1 - i];
                const originTokenAddress = await origin.service.getTokenAddress(tokenId);
                const destTokenAddress = await origin.service.getTokenAddress(tokenId);
                originToken = new Contract(originTokenAddress, Token.abi, origin.ownerWallet);
                destToken = new Contract(destTokenAddress, Token.abi, dest.ownerWallet);

                expect(await originToken.balanceOf(origin.ownerWallet.address)).to.equal(amount * 2);
                expect(await destToken.balanceOf(dest.ownerWallet.address)).to.equal(0);
            });

            it('Should be able to interchainTransfer some token to another chain', async () => {
                const blockNumber = await origin.provider.getBlockNumber();
                const sendHash = keccak256(
                    defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, origin.ownerWallet.address]),
                );

                await expect(originToken.interchainTransfer(dest.name, dest.ownerWallet.address, amount, '0x', { value: 1e6 }))
                    .to.emit(origin.service, 'Sending')
                    .withArgs(dest.name, origin.ownerWallet.address.toLowerCase(), amount, sendHash);

                expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount);

                await relay();

                expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
            });

            it('Should be able to interchainTransferFrom some token to another chain', async () => {
                await originToken.approve(origin.otherWallet.address, amount);
                const blockNumber = await origin.provider.getBlockNumber();
                const sendHash = keccak256(
                    defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, origin.ownerWallet.address]),
                );

                await expect(
                    originToken
                        .connect(origin.otherWallet)
                        .interchainTransferFrom(origin.ownerWallet.address, dest.name, dest.ownerWallet.address, amount, '0x', {
                            value: 1e6,
                        }),
                )
                    .to.emit(origin.service, 'Sending')
                    .withArgs(dest.name, origin.ownerWallet.address.toLowerCase(), amount, sendHash);

                expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(0);

                await relay();

                expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount * 2);
            });
        });
    }

    for (let i = 0; i < 2; i++) {
        describe(`Should send token with data from ${i} to ${1 - i}`, () => {
            before(async () => {
                origin = chains[i];
                dest = chains[1 - i];
                const originTokenAddress = await origin.service.getTokenAddress(tokenId);
                const destTokenAddress = await origin.service.getTokenAddress(tokenId);
                originToken = new Contract(originTokenAddress, Token.abi, origin.ownerWallet);
                destToken = new Contract(destTokenAddress, Token.abi, dest.ownerWallet);

                expect(await originToken.balanceOf(origin.ownerWallet.address)).to.equal(amount * 2);
                expect(await destToken.balanceOf(dest.ownerWallet.address)).to.equal(0);
            });

            it('Should be able to interchainTransfer some token to another chain', async () => {
                const val = `interchainTransfer ${i}`;
                const payload = defaultAbiCoder.encode(['address', 'string'], [dest.ownerWallet.address, val]);

                const blockNumber = await origin.provider.getBlockNumber();
                const sendHash = keccak256(
                    defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, origin.ownerWallet.address]),
                );

                await expect(originToken.interchainTransfer(dest.name, dest.executable.address, amount, payload, { value: 1e6 }))
                    .to.emit(origin.service, 'SendingWithData')
                    .withArgs(origin.ownerWallet.address, dest.name, origin.executable.address.toLowerCase(), amount, payload, sendHash);

                expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(amount);

                await relay();

                expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount);
            });

            it('Should be able to interchainTransferFrom some token to another chain', async () => {
                const val = `interchainTransferFrom ${i}`;
                const payload = defaultAbiCoder.encode(['address', 'string'], [dest.ownerWallet.address, val]);

                await originToken.approve(origin.otherWallet.address, amount);

                const blockNumber = await origin.provider.getBlockNumber();
                const sendHash = keccak256(
                    defaultAbiCoder.encode(['uint256', 'bytes32', 'address'], [blockNumber + 1, tokenId, origin.ownerWallet.address]),
                );

                await expect(
                    originToken
                        .connect(origin.otherWallet)
                        .interchainTransferFrom(origin.ownerWallet.address, dest.name, dest.executable.address, amount, payload, {
                            value: 1e6,
                        }),
                )
                    .to.emit(origin.service, 'SendingWithData')
                    .withArgs(origin.ownerWallet.address, dest.name, origin.executable.address.toLowerCase(), amount, payload, sendHash);

                expect(Number(await originToken.balanceOf(origin.ownerWallet.address))).to.equal(0);

                await relay();

                expect(Number(await destToken.balanceOf(dest.ownerWallet.address))).to.equal(amount * 2);
            });
        });
    }
});
