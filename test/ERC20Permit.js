'use strict';

const { ethers } = require('hardhat');
const {
    getContractAt,
    utils: { splitSignature },
    constants: { MaxUint256 },
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32, expectRevert, getChainId } = require('./utils');
const { deployContract } = require('../scripts/deploy');

describe('ERC20 Permit', () => {
    let interchainToken, interchainTokenDeployer;

    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    let token;

    let owner, user;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];

        interchainToken = await deployContract(owner, 'InterchainToken', [owner.address]);
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [interchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('InterchainToken', tokenAddress, owner);

        await interchainTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals).then((tx) => tx.wait);

        await token.mint(owner.address, mintAmount).then((tx) => tx.wait);
        expect(await token.interchainTokenId()).to.equal(tokenId);
    });

    it('should set allowance by verifying permit', async () => {
        const deadline = Math.floor(Date.now() / 1000) + 1000;
        const allowance = 10000;

        const nonce = await token.nonces(owner.address);

        const signature = splitSignature(
            await owner._signTypedData(
                {
                    name,
                    version: '1',
                    chainId: getChainId(),
                    verifyingContract: token.address,
                },
                {
                    Permit: [
                        { name: 'owner', type: 'address' },
                        { name: 'spender', type: 'address' },
                        { name: 'value', type: 'uint256' },
                        { name: 'nonce', type: 'uint256' },
                        { name: 'deadline', type: 'uint256' },
                    ],
                },
                {
                    owner: owner.address,
                    spender: user.address,
                    value: allowance,
                    nonce,
                    deadline,
                },
            ),
        );

        await expect(
            token
                .connect(owner)
                .permit(owner.address, user.address, allowance, deadline, signature.v, signature.r, signature.s, { gasLimit: 8000000 }),
        )
            .to.emit(token, 'Approval')
            .withArgs(owner.address, user.address, allowance);

        expect(await token.nonces(owner.address)).to.equal(nonce.add(1));

        expect(await token.allowance(owner.address, user.address)).to.equal(allowance);
    });

    it('should revert if permit is expired', async () => {
        const deadline = 100;
        const allowance = 10000;

        const signature = splitSignature(
            await user._signTypedData(
                {
                    name: 'test',
                    version: '1',
                    chainId: await getChainId(),
                    verifyingContract: token.address,
                },
                {
                    Permit: [
                        { name: 'owner', type: 'address' },
                        { name: 'spender', type: 'address' },
                        { name: 'value', type: 'uint256' },
                        { name: 'nonce', type: 'uint256' },
                        { name: 'deadline', type: 'uint256' },
                    ],
                },
                {
                    owner: user.address,
                    spender: owner.address,
                    value: allowance,
                    nonce: 0,
                    deadline,
                },
            ),
        );

        await expectRevert(
            (gasOptions) =>
                token
                    .connect(owner)
                    .permit(user.address, owner.address, allowance, deadline, signature.v, signature.r, signature.s, gasOptions),
            token,
            'PermitExpired',
        );
    });

    it('should revert if signature is incorrect', async () => {
        const deadline = (1000 + Date.now() / 1000) | 0;
        const allowance = 10000;

        const signature = splitSignature(
            await user._signTypedData(
                {
                    name: 'test',
                    version: '1',
                    chainId: await getChainId(),
                    verifyingContract: token.address,
                },
                {
                    Permit: [
                        { name: 'owner', type: 'address' },
                        { name: 'spender', type: 'address' },
                        { name: 'value', type: 'uint256' },
                        { name: 'nonce', type: 'uint256' },
                        { name: 'deadline', type: 'uint256' },
                    ],
                },
                {
                    owner: user.address,
                    spender: owner.address,
                    value: allowance,
                    nonce: 0,
                    deadline,
                },
            ),
        );

        await expectRevert(
            (gasOptions) =>
                token
                    .connect(owner)
                    .permit(user.address, owner.address, allowance, deadline, signature.v, signature.r, MaxUint256, gasOptions),
            token,
            'InvalidS',
        );

        await expectRevert(
            (gasOptions) =>
                token
                    .connect(owner)
                    .permit(owner.address, owner.address, allowance, deadline, signature.v, signature.r, signature.s, gasOptions),
            token,
            'InvalidSignature',
        );
    });
});
