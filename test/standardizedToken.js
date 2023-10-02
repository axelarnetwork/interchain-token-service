'use strict';

const chai = require('chai');
const { ethers } = require('hardhat');
const {
    Contract,
    utils: { splitSignature, keccak256, toUtf8Bytes },
    constants: { MaxUint256, AddressZero },
} = ethers;
const { expect } = chai;
const { getRandomBytes32, getChainId, expectRevert, getGasOptions } = require('../scripts/utils');
const { deployContract } = require('../scripts/deploy');

const StandardizedToken = require('../artifacts/contracts/token-implementations/StandardizedToken.sol/StandardizedToken.json');
const StandardizedTokenProxy = require('../artifacts/contracts/proxies/StandardizedTokenProxy.sol/StandardizedTokenProxy.json');

describe.only('StandardizedToken', () => {
    let standardizedToken, standardizedTokenDeployer;

    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let tokenProxy;

    let owner, user;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
    });

    beforeEach(async () => {
        standardizedToken = await deployContract(owner, 'StandardizedToken');
        standardizedTokenDeployer = await deployContract(owner, 'StandardizedTokenDeployer', [standardizedToken.address]);

        const salt = getRandomBytes32();

        const tokenAddress = await standardizedTokenDeployer.deployedAddress(salt);

        token = new Contract(tokenAddress, StandardizedToken.abi, owner);
        tokenProxy = new Contract(tokenAddress, StandardizedTokenProxy.abi, owner);

        await standardizedTokenDeployer.deployStandardizedToken(
            salt,
            owner.address,
            owner.address,
            name,
            symbol,
            decimals,
            mintAmount,
            owner.address,
        );
    });

    describe('Standardized Token Proxy', () => {
        it('should revert if standardized token implementation is invalid', async () => {
            const invalidStandardizedToken = await deployContract(owner, 'InvalidStandardizedToken');
            standardizedTokenDeployer = await deployContract(owner, 'StandardizedTokenDeployer', [invalidStandardizedToken.address]);

            const salt = getRandomBytes32();

            await expect(
                standardizedTokenDeployer.deployStandardizedToken(
                    salt,
                    owner.address,
                    owner.address,
                    name,
                    symbol,
                    decimals,
                    mintAmount,
                    owner.address,
                    getGasOptions(),
                ),
            ).to.be.reverted;
        });

        it('should return the correct contract ID', async () => {
            const contractID = await token.contractId();
            const hash = keccak256(toUtf8Bytes('standardized-token'));
            expect(contractID).to.equal(hash);
        });
    });

    describe('Standardized Token', () => {
        it('revert on setup if not called by the proxy', async () => {
            const implementationAddress = await tokenProxy.implementation();
            const implementation = new Contract(implementationAddress, StandardizedToken.abi, owner);

            const params = '0x';
            await expectRevert((gasOptions) => implementation.setup(params, gasOptions), token, 'NotProxy');
        });
    });

    describe('ERC20 Basics', () => {
        it('should increase and decrease allowance', async () => {
            const initialAllowance = await token.allowance(user.address, owner.address);
            expect(initialAllowance).to.eq(0);

            await expect(token.connect(user).increaseAllowance(owner.address, MaxUint256))
                .to.emit(token, 'Approval')
                .withArgs(user.address, owner.address, MaxUint256);

            const increasedAllowance = await token.allowance(user.address, owner.address);
            expect(increasedAllowance).to.eq(MaxUint256);

            await expect(token.connect(user).decreaseAllowance(owner.address, MaxUint256))
                .to.emit(token, 'Approval')
                .withArgs(user.address, owner.address, 0);

            const finalAllowance = await token.allowance(user.address, owner.address);
            expect(finalAllowance).to.eq(0);
        });

        it('should revert on approve with invalid owner or sender', async () => {
            await expectRevert(
                (gasOptions) => token.connect(owner).transferFrom(AddressZero, owner.address, 0, gasOptions),
                token,
                'InvalidAccount',
            );

            await expectRevert(
                (gasOptions) => token.connect(user).increaseAllowance(AddressZero, MaxUint256, gasOptions),
                token,
                'InvalidAccount',
            );
        });

        it('should revert on transfer to invalid address', async () => {
            const initialAllowance = await token.allowance(user.address, owner.address);
            expect(initialAllowance).to.eq(0);

            await expect(token.connect(user).increaseAllowance(owner.address, MaxUint256))
                .to.emit(token, 'Approval')
                .withArgs(user.address, owner.address, MaxUint256);

            const increasedAllowance = await token.allowance(user.address, owner.address);
            expect(increasedAllowance).to.eq(MaxUint256);

            const amount = 100;

            await expectRevert(
                (gasOptions) => token.connect(owner).transferFrom(user.address, AddressZero, amount, gasOptions),
                token,
                'InvalidAccount',
            );
        });

        it('should revert mint or burn to invalid address', async () => {
            const amount = 100;
            await expectRevert((gasOptions) => token.mint(AddressZero, amount, gasOptions), token, 'InvalidAccount');
            await expectRevert((gasOptions) => token.burn(AddressZero, amount, gasOptions), token, 'InvalidAccount');
        });
    });

    describe('ERC20 Permit', () => {
        it('should set allowance by verifying permit', async () => {
            const deadline = Math.floor(Date.now() / 1000) + 1000;
            const allowance = 10000;

            const nonce = await token.nonces(owner.address);

            const signature = splitSignature(
                await owner._signTypedData(
                    {
                        name,
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
                    token.connect(owner).permit(user.address, owner.address, allowance, deadline, 0, signature.r, signature.s, gasOptions),
                token,
                'InvalidV',
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
});
