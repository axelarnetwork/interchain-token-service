'use strict';

const { ethers } = require('hardhat');
const {
    constants: { AddressZero, HashZero, MaxUint256 },
    getContractAt,
    utils: { keccak256 },
} = ethers;
const { expect } = require('chai');
const { getRandomBytes32, expectRevert, getEVMVersion } = require('./utils');
const { deployContract, deployAll } = require('../scripts/deploy');

describe('InterchainToken', () => {
    let interchainToken, interchainTokenDeployer;
    let service, gateway, gasService;

    const name = 'tokenName';
    const symbol = 'tokenSymbol';
    const decimals = 18;
    const mintAmount = 123;

    let token;
    let tokenTest;
    let owner;
    let user;
    let deployer;

    before(async () => {
        const wallets = await ethers.getSigners();
        owner = wallets[0];
        user = wallets[1];
        deployer = wallets[1];

        ({ service, gateway, gasService } = await deployAll(owner, 'Test'));

        interchainToken = await deployContract(owner, 'InterchainToken', [service.address]);
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [interchainToken.address]);

        const salt = getRandomBytes32();
        const tokenId = getRandomBytes32();

        const tokenAddress = await interchainTokenDeployer.deployedAddress(salt);

        token = await getContractAt('InterchainToken', tokenAddress, owner);

        await interchainTokenDeployer.deployInterchainToken(salt, tokenId, owner.address, name, symbol, decimals).then((tx) => tx.wait);

        await token.mint(owner.address, mintAmount).then((tx) => tx.wait);
        expect(await token.interchainTokenId()).to.equal(tokenId);
    });

    describe('Interchain Token', () => {
        it('Should calculate hardcoded constants correctly', async () => {
            await expect(deployContract(owner, `TestInterchainToken`, [])).to.not.be.reverted;
        });

        it('revert on init if not called by the proxy', async () => {
            const implementationAddress = await interchainTokenDeployer.implementationAddress();
            const implementation = await getContractAt('InterchainToken', implementationAddress, owner);

            const tokenId = getRandomBytes32();
            const minter = owner.address;
            const tokenName = 'name';
            const tokenSymbol = 'symbol';
            const tokenDecimals = 7;
            await expectRevert(
                (gasOptions) => implementation.init(tokenId, minter, tokenName, tokenSymbol, tokenDecimals, gasOptions),
                implementation,
                'AlreadyInitialized',
            );
        });

        it('revert on init if service is address(0)', async () => {
            await expectRevert(
                (gasOptions) => deployContract(owner, 'InterchainToken', [AddressZero, gasOptions]),
                interchainToken,
                'InterchainTokenServiceAddressZero',
            );
        });

        it('revert on init if tokenId is 0', async () => {
            const salt = getRandomBytes32();
            const minter = owner.address;
            await expectRevert(
                (gasOptions) => interchainTokenDeployer.deployInterchainToken(salt, HashZero, minter, name, symbol, decimals, gasOptions),
                interchainToken,
                'TokenIdZero',
            );
        });

        it('revert on init if token name is invalid', async () => {
            const salt = getRandomBytes32();
            const tokenId = getRandomBytes32();
            const minter = owner.address;
            await expectRevert(
                (gasOptions) => interchainTokenDeployer.deployInterchainToken(salt, tokenId, minter, '', symbol, decimals, gasOptions),
                interchainToken,
                'TokenNameEmpty',
            );
        });

        it('revert on init if token symbol is invalid', async () => {
            const salt = getRandomBytes32();
            const tokenId = getRandomBytes32();
            const minter = owner.address;
            await expectRevert(
                (gasOptions) => interchainTokenDeployer.deployInterchainToken(salt, tokenId, minter, name, '', decimals, gasOptions),
                interchainToken,
                'TokenSymbolEmpty',
            );
        });

        it('should subtract from the spender allowance', async () => {
            tokenTest = await deployContract(owner, 'TestInterchainToken', []);

            const sender = owner.address;
            const spender = user.address;
            const amount = 100;

            await tokenTest.approve(spender, amount).then((tx) => tx.wait);
            const initialAllowance = await tokenTest.allowance(sender, spender);
            expect(initialAllowance).to.eq(amount);

            await expect(tokenTest.spendAllowance(sender, spender, amount)).to.emit(tokenTest, 'Approval').withArgs(sender, spender, 0);

            const finalAllowance = await tokenTest.allowance(sender, spender);
            expect(finalAllowance).to.eq(0);
        });

        it('should not subtract from the spender allowance if allowance is max uint', async () => {
            tokenTest = await deployContract(owner, 'TestInterchainToken', []);

            const sender = owner.address;
            const spender = user.address;
            const amount = MaxUint256;

            await tokenTest.approve(spender, amount).then((tx) => tx.wait);
            const initialAllowance = await tokenTest.allowance(sender, spender);
            expect(initialAllowance).to.eq(amount);

            await expect(tokenTest.spendAllowance(sender, spender, amount)).to.not.emit(tokenTest, 'Approval');

            const finalAllowance = await tokenTest.allowance(sender, spender);
            expect(finalAllowance).to.eq(initialAllowance);
        });

        it('should get the correct deployer address as 0x when no deployer is set', async () => {
            const deployer = await token.getDeployer();
            expect(deployer).to.equal(AddressZero);
        });

        it('should get the correct deployer address after updateDeployer', async () => {
            await token.connect(owner).updateDeployer(deployer.address);
            const newDeployer = await token.getDeployer();
            expect(newDeployer).to.equal(deployer.address);
        });

        it('should revert when non-ITS or non-operator tries to update deployer', async () => {
            await expect(
                token.connect(user).updateDeployer(user.address)
            ).to.be.reverted;
        });
    });

    describe('Bytecode checks [ @skip-on-coverage ]', () => {
        it('Should preserve the same bytecode', async () => {
            const contract = await ethers.getContractFactory('InterchainToken', owner);
            const contractBytecode = contract.bytecode;
            const contractBytecodeHash = keccak256(contractBytecode);

            const expected = {
                london: '0xaed0b35ad6bea174eb976222060ce7cf0867869e1c9b9c4d12b2d5cf0749d5e2',
            }[getEVMVersion()];

            expect(contractBytecodeHash).to.be.equal(expected);
        });
    });
});
